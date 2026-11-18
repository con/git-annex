{- P2P protocol over HTTP, server state
 -
 - https://git-annex.branchable.com/design/p2p_protocol_over_http/
 -
 - Copyright 2024-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

module P2P.Http.State where

import Annex.Common
import qualified Annex
import P2P.Http.Types
import P2P.Http.Types.Internal
import P2P.Http.Connection
import P2P.Http.Workers
import qualified P2P.Protocol as P2P
import qualified P2P.IO as P2P
import P2P.IO
import Annex.UUID
import Annex.BranchState
import Annex.Concurrent
import Utility.ThreadScheduler
import Logs.Proxy
import qualified Annex.Branch

import Servant
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Control.Concurrent.Async
import Control.Concurrent.STM
import Data.Unique

getPerRepoServerState :: TMVar P2PHttpServerState -> B64UUID ServerSide -> IO (Maybe PerRepoServerState)
getPerRepoServerState mstv su = do
	mst <- atomically $ readTMVar mstv
	case lookupst mst of
		Just st -> return (Just st)
		Nothing -> do
			mst' <- atomically $ takeTMVar mstv
			mst'' <- updateRepos mst' mst'
			debug "P2P.Http" $
				"Rescanned for repositories, now serving UUIDs: "
					++ show (M.keys (servedRepos mst''))
			atomically $ putTMVar mstv mst''
			return $ lookupst mst''
  where
	lookupst mst = M.lookup (fromB64UUID su) (servedRepos mst)

proxyClientNetProto :: P2PConnectionPair -> P2P.Proto a -> IO (Either P2P.ProtoFailure a)
proxyClientNetProto conn = runNetProto
	(clientRunState conn) (clientP2PConnection conn)

consumeLockedFilesQSem :: PerRepoServerState -> IO Bool
consumeLockedFilesQSem st = atomically $ do
	n <- takeTMVar (lockedFilesQSem st)
	if n < 1
		then do
			putTMVar (lockedFilesQSem st) n
			return False
		else do
			putTMVar (lockedFilesQSem st) (pred n)
			return True

releaseLockedFilesQSem :: PerRepoServerState -> IO ()
releaseLockedFilesQSem st = atomically $ do
	n <- takeTMVar (lockedFilesQSem st)
	putTMVar (lockedFilesQSem st) (succ n)

mkP2PHttpServerState
	:: GetServerMode
	-> UpdateRepos
	-> ProxyConnectionPoolSize
	-> ClusterConcurrency
	-> LockedFilesQSem
	-> TMVar ProxyConnectionPool
	-> AnnexWorkerLimit	
	-> AnnexWorkerPool
	-> ProxyRunnerMap
	-> Annex P2PHttpServerState
mkP2PHttpServerState getservermode updaterepos proxyconnectionpoolsize clusterconcurrency lockedfilesqsem proxypool workerlimit workerpool proxyrunnermap = do
	enableInteractiveBranchAccess
	myuuid <- getUUID
	myproxies <- M.lookup myuuid <$> getProxies
	reqv <- liftIO newEmptyTMVarIO
	relv <- liftIO newEmptyTMVarIO
	endv <- liftIO newEmptyTMVarIO
	asyncservicer <- liftIO $ async $
		servicer myuuid myproxies reqv relv endv
	let servinguuids = myuuid : map proxyRemoteUUID (maybe [] S.toList myproxies)
	annexstate <- liftIO . newTMVarIO =<< dupState
	annexread <- Annex.getRead id
	st <- liftIO $ mkPerRepoServerState 
		(acquireconn reqv annexstate annexread)
		workerpool annexstate annexread getservermode lockedfilesqsem
	asynccommitter <- liftIO $ async $
		branchCommitter st endv workerlimit workerpool
	let endit = do
		liftIO $ atomically $ putTMVar endv ()
		liftIO $ wait asyncservicer
		liftIO $ wait asynccommitter
	return $ P2PHttpServerState
		{ servedRepos = M.fromList $ zip servinguuids (repeat st)
		, serverShutdownCleanup = endit
		, updateRepos = updaterepos
		}
  where
	acquireconn reqv annexstate annexread runnertype connparams = do
		ready <- newEmptyTMVarIO
		respvar <- newEmptyTMVarIO
		atomically $ putTMVar reqv (runnertype, annexstate, annexread, connparams, ready, respvar)
		() <- atomically $ takeTMVar ready
		atomically $ takeTMVar respvar

	servicer myuuid myproxies reqv relv endv = do
		reqrel <- liftIO $
			atomically $ 
				(Right <$> takeTMVar reqv)
					`orElse` 
				(Left . Right <$> takeTMVar relv)
					`orElse` 
				(Left . Left <$> readTMVar endv)
		case reqrel of
			Right (runnertype, annexstate, annexread, connparams, ready, respvar) -> do
				servicereq runnertype annexstate annexread myuuid myproxies relv connparams ready
					>>= atomically . putTMVar respvar
				servicer myuuid myproxies reqv relv endv
			Left (Right releaseconn) -> do
				void $ tryNonAsync releaseconn
				servicer myuuid myproxies reqv relv endv
			Left (Left ()) -> return ()
	
	servicereq runnertype annexstate annexread myuuid myproxies relv connparams ready
		| connectionServerUUID connparams == myuuid =
			localConnection relv connparams runner ready
		| otherwise = do
			proxykey <- mkProxyConnectionKey connparams
				. Just <$> newUnique
			atomically (getProxyConnectionPool proxypool proxykey) >>= \case
				Just (proxykey', conn) -> do
					proxyrunner <- getProxyRunner proxyrunnermap proxykey'
					proxyConnection proxyconnectionpoolsize relv connparams proxyrunner proxypool proxyrunnermap conn ready
				Nothing -> openProxyConnection myproxies proxyrunnermap proxypool proxyconnectionpoolsize clusterconcurrency proxykey relv connparams ready
	  where
		runner = annexActionRunner runnertype workerlimit workerpool annexstate annexread

mkServerRunState :: ConnectionParams -> IO RunState
mkServerRunState connparams = do
	prototvar <- newTVarIO $ connectionProtocolVersion connparams
	mkRunState $ const $ Serving 
		(connectionClientUUID connparams)
		Nothing
		prototvar
	
mkClientRunState :: ConnectionParams -> IO RunState
mkClientRunState connparams = do
	prototvar <- newTVarIO $ connectionProtocolVersion connparams
	mkRunState $ const $ Client prototvar

-- Use when running an action which may journal git-annex branch changes.
-- This arranges for the journalled changes to be committed to the branch
-- in a timely fashion, so that eg, soon after one client has sent a file,
-- another client can pull the branch and see that the file is present in
-- the server.
changesBranch :: TMVar P2PHttpServerState -> B64UUID ServerSide -> Handler t -> Handler t
changesBranch mstv su a = liftIO (getPerRepoServerState mstv su) >>= \case
	Just st -> bracket_ (send st True) (send st False) a
	Nothing -> a
  where
	send st b = liftIO $ atomically $ 
		putTMVar (branchChangesInProgress st) b

branchCommitter :: PerRepoServerState -> TMVar () -> AnnexWorkerLimit -> AnnexWorkerPool -> IO ()
branchCommitter st endv workerlimit workerpool = do
	idlev <- newEmptyTMVarIO
	void $ async $ committer idlev
	go idlev (0 :: Integer)
  where
	waitchangeorend = (Right <$> takeTMVar (branchChangesInProgress st))
		`orElse` (Left <$> readTMVar endv)
	go idlev n = atomically waitchangeorend >>= \case
		Right True -> do
			let !n' = succ n
			-- Not idle.
			void $ atomically $ tryTakeTMVar idlev
			go idlev n'
		Right False -> do
			let n' = pred n
			when (n' == 0) $
				-- Idle.
				atomically $ writeTMVar idlev ()
			go idlev n'
		Left () -> return ()
	waitidleorend idlev = 
		(Right <$> readTMVar idlev)
			`orElse` (Left <$> readTMVar endv)
	committer idlev =
		-- Wait until a change has completed and it's idle.
		atomically (waitidleorend idlev) >>= \case
			Right () -> do
				threadDelaySeconds (SecondsDelay 1)
				-- Once it's been idle for a second,
				-- commit the journalled changes.
				atomically (tryTakeTMVar idlev) >>= \case
					Just () -> runcommit
					Nothing -> noop
				committer idlev
			Left () -> return ()

	runcommit =
		-- Use a warmed up AnnexWorker to do the commit when possible.
		-- But, if the server is too busy, the commit still needs
		-- to happen promptly. So avoid blocking and fall back
		-- to running the commit using the RequestRunner Annex
		-- state. Which then needs to be quiesced, which makes
		-- it less efficient.
		inAnnexWorkerNonBlocking workerlimit workerpool commit >>= \case
			Just _ -> return ()
			Nothing -> void $ handleRequestAnnex st $ do
				commit
				quiesceRequestAnnex workerlimit
	
	commit = Annex.Branch.commit =<< Annex.Branch.commitMessage

withP2PConnection
	:: APIVersion v
	=> v
	-> AnnexActionRunner
	-> TMVar P2PHttpServerState
	-> B64UUID ClientSide
	-> B64UUID ServerSide
	-> [B64UUID Bypass]
	-> IsSecure
	-> Maybe Auth
	-> ActionClass
	-> (ConnectionParams -> ConnectionParams)
	-> ((P2PConnectionPair, PerRepoServerState) -> Handler (Either ProtoFailure a))
	-> Handler a
withP2PConnection apiver runner mst cu su bypass sec auth actionclass fconnparams connaction =
	withP2PConnection' apiver runner mst cu su bypass sec auth actionclass fconnparams connaction'
  where
	connaction' conn = connaction conn >>= \case
		Right r -> return r
		Left err -> throwError $
			err500 { errBody = encodeBL (describeProtoFailure err) }

withP2PConnection'
	:: APIVersion v
	=> v
	-> AnnexActionRunner
	-> TMVar P2PHttpServerState
	-> B64UUID ClientSide
	-> B64UUID ServerSide
	-> [B64UUID Bypass]
	-> IsSecure
	-> Maybe Auth
	-> ActionClass
	-> (ConnectionParams -> ConnectionParams)
	-> ((P2PConnectionPair, PerRepoServerState) -> Handler a)
	-> Handler a
withP2PConnection' apiver runner mst cu su bypass sec auth actionclass fconnparams connaction = do
	(conn, st) <- getP2PConnection apiver runner mst cu su bypass sec auth actionclass fconnparams
	connaction (conn, st)
		`finally` liftIO (releaseP2PConnection conn)

getP2PConnection
	:: APIVersion v
	=> v
	-> AnnexActionRunner
	-> TMVar P2PHttpServerState
	-> B64UUID ClientSide
	-> B64UUID ServerSide
	-> [B64UUID Bypass]
	-> IsSecure
	-> Maybe Auth
	-> ActionClass
	-> (ConnectionParams -> ConnectionParams)
	-> Handler (P2PConnectionPair, PerRepoServerState)
getP2PConnection apiver runner mst cu su bypass sec auth actionclass fconnparams =
	checkAuthActionClass mst su sec auth actionclass $
		getP2PConnection' apiver runner cu su bypass fconnparams

getP2PConnection'
	:: APIVersion v
	=> v
	-> AnnexActionRunner
	-> B64UUID ClientSide
	-> B64UUID ServerSide
	-> [B64UUID Bypass]
	-> (ConnectionParams -> ConnectionParams)
	-> PerRepoServerState
	-> P2P.ServerMode
	-> Handler (P2PConnectionPair, PerRepoServerState)
getP2PConnection' apiver runner cu su bypass fconnparams st servermode =
	liftIO (acquireP2PConnection st runner cp) >>= \case
		Left (ConnectionFailed err) -> 
			throwError err502 { errBody = encodeBL err }
		Left TooManyConnections ->
			throwError err503
		Right v -> return (v, st)
  where
	cp = fconnparams $ ConnectionParams
		{ connectionProtocolVersion = protocolVersion apiver
		, connectionServerUUID = fromB64UUID su
		, connectionClientUUID = fromB64UUID cu
		, connectionBypass = map fromB64UUID bypass
		, connectionServerMode = servermode
		, connectionWaitVar = True
		}

checkAuthActionClass
	:: TMVar P2PHttpServerState
	-> B64UUID ServerSide
	-> IsSecure
	-> Maybe Auth
	-> ActionClass
	-> (PerRepoServerState -> P2P.ServerMode -> Handler a)
	-> Handler a
checkAuthActionClass mstv su sec auth actionclass go =
	liftIO (getPerRepoServerState mstv su) >>= \case
		Just st -> select st
		Nothing -> throwError err404
  where
	select st = case (sm, actionclass) of
		(ServerMode { serverMode = P2P.ServeReadWrite }, _) ->
			go st P2P.ServeReadWrite
		(ServerMode { unauthenticatedLockingAllowed = True }, LockAction) ->
			go st P2P.ServeReadOnly
		(ServerMode { serverMode = P2P.ServeAppendOnly }, RemoveAction) -> 
			throwError $ forbiddenWithoutAuth sm
		(ServerMode { serverMode = P2P.ServeAppendOnly }, _) ->
			go st P2P.ServeAppendOnly
		(ServerMode { serverMode = P2P.ServeReadOnly }, ReadAction) ->
			go st P2P.ServeReadOnly
		(ServerMode { serverMode = P2P.ServeReadOnly }, _) -> 
			throwError $ forbiddenWithoutAuth sm
		(CannotServeRequests, _) -> throwError basicAuthRequired
	  where
		sm = getServerMode st sec auth

forbiddenAction :: ServerError
forbiddenAction = err403

basicAuthRequired :: ServerError
basicAuthRequired = err401 { errHeaders = [(h, v)] }
  where
	h = "WWW-Authenticate"
	v = "Basic realm=\"git-annex\", charset=\"UTF-8\""

forbiddenWithoutAuth :: ServerMode -> ServerError
forbiddenWithoutAuth sm
	| authenticationAllowed sm = basicAuthRequired
	| otherwise = forbiddenAction
