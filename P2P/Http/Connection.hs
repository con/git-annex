{- P2P protocol over HTTP, P2P connections
 -
 - https://git-annex.branchable.com/design/p2p_protocol_over_http/
 -
 - Copyright 2024-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TupleSections #-}

module P2P.Http.Connection where

import Annex.Common
import P2P.Http.Types.Internal
import P2P.Http.Workers
import qualified P2P.Protocol as P2P
import P2P.IO
import P2P.Annex
import Annex.Action
import Types.Cluster
import Logs.Proxy
import Annex.Proxy
import Annex.Cluster
import qualified P2P.Proxy as Proxy
import qualified Types.Remote as Remote
import Remote.List

import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Control.Concurrent.Async
import Control.Concurrent.STM
import Data.Time.Clock.POSIX

openProxyConnection
	::  Maybe (S.Set Logs.Proxy.Proxy)
	-> ProxyRunnerMap
	-> TMVar ProxyConnectionPool
	-> ProxyConnectionPoolSize
	-> ClusterConcurrency
	-> ProxyConnectionKey
	-> TMVar (IO ())
	-> ConnectionParams
	-> TMVar ()
	-> IO (Either ConnectionProblem P2PConnectionPair)
openProxyConnection myproxies proxyrunnermap proxypool proxyconnectionpoolsize clusterconcurrency proxykey relv connparams ready = do
	proxyrunner <- getProxyRunner proxyrunnermap proxykey
	let unusable reason = do
		void $ (proxyRunner proxyrunner) (quiesce True)
		return $ Left $ ConnectionFailed reason
	(proxyRunner proxyrunner)
		(checkCanProxy' myproxies (connectionServerUUID connparams)) >>= \case
			Right (Right (Right proxyremote)) ->
				proxyconnection proxyrunner $ openProxyConnectionToRemote
					(connectionProtocolVersion connparams)
					bypass proxyremote proxykey
			Right (Right (Left clusteruuid)) ->
				proxyconnection proxyrunner $ openProxyConnectionToCluster
					(connectionProtocolVersion connparams)
					bypass clusteruuid clusterconcurrency proxykey
			Right (Left reason) -> 
				unusable $ fromMaybe "unknown uuid" reason
			Left ex ->
				unusable $ show ex
  where
	bypass = P2P.Bypass $ S.fromList $ connectionBypass connparams
	proxyconnection proxyrunner openconn =
		(proxyRunner proxyrunner) openconn >>= \case
			Right conn -> proxyConnection proxyconnectionpoolsize
				relv connparams proxyrunner proxypool proxyrunnermap conn ready
			Left ex -> return $ Left $
				ConnectionFailed $ show ex

localConnection
	:: TMVar (IO ())
	-> ConnectionParams
	-> (Annex () -> IO (Either SomeException ()))
	-> TMVar ()
	-> IO (Either ConnectionProblem P2PConnectionPair)
localConnection relv connparams runner ready = 
	localP2PConnectionPair connparams relv $ \serverrunst serverconn ->
		runner $ do
			liftIO $ atomically $ putTMVar ready ()
			void $ runFullProto serverrunst remoteList serverconn $
				P2P.serveOneCommandAuthed
					(connectionServerMode connparams)
					(connectionServerUUID connparams)

localP2PConnectionPair
	:: ConnectionParams
	-> TMVar (IO ())
	-> (RunState -> P2PConnection -> IO (Either SomeException ()))
	-> IO (Either ConnectionProblem P2PConnectionPair)
localP2PConnectionPair connparams relv startworker = do
	(clientconn, serverconn) <- mkP2PConnectionPair connparams
		("http client", "http server")
	clientrunst <- mkClientRunState connparams
	serverrunst <- mkServerRunState connparams
	asyncworker <- async $
		startworker serverrunst serverconn
	let releaseconn closeit = atomically $ void $ tryPutTMVar relv $ do
		when closeit $ do
			liftIO $ closeConnection clientconn
			liftIO $ closeConnection serverconn
		liftIO $ wait asyncworker
			>>= either throwM return
	return $ Right $ P2PConnectionPair
		{ clientRunState = clientrunst
		, clientP2PConnection = clientconn
		, serverP2PConnection = serverconn
		, releaseP2PConnection = releaseconn False
		, closeP2PConnection = releaseconn True
		}

mkP2PConnectionPair
	:: ConnectionParams
	-> (String, String)
	-> IO (P2PConnection, P2PConnection)
mkP2PConnectionPair connparams (n1, n2) = do
	hdl1 <- newEmptyTMVarIO
	hdl2 <- newEmptyTMVarIO
	wait1 <- newEmptyTMVarIO
	wait2 <- newEmptyTMVarIO
	closed1 <- newEmptyTMVarIO
	closed2 <- newEmptyTMVarIO
	let h1 = P2PHandleTMVar hdl1
		(if connectionWaitVar connparams then Just wait1 else Nothing)
		closed1
	let h2 = P2PHandleTMVar hdl2
		(if connectionWaitVar connparams then Just wait2 else Nothing)
		closed2
	let clientconn = P2PConnection Nothing
		(const True) h2 h1 Nothing
		(ConnIdent (Just n1))
	let serverconn = P2PConnection Nothing
		(const True) h1 h2 Nothing
		(ConnIdent (Just n2))
	return (clientconn, serverconn)

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

proxyConnection
	:: ProxyConnectionPoolSize
	-> TMVar (IO ())
	-> ConnectionParams
	-> ProxyRunner
	-> TMVar ProxyConnectionPool
	-> ProxyRunnerMap
	-> ProxyConnection
	-> TMVar ()
	-> IO (Either ConnectionProblem P2PConnectionPair)
proxyConnection proxyconnectionpoolsize relv connparams runner proxypool proxyrunnermap proxyconn ready = do
	(clientconn, proxyfromclientconn) <- 
		mkP2PConnectionPair connparams ("http client", "proxy")
	clientrunst <- mkClientRunState connparams
	proxyfromclientrunst <- mkClientRunState connparams
	asyncworker <- async $ (proxyRunner runner) $ do
		liftIO $ atomically $ putTMVar ready ()
		proxystate <- liftIO Proxy.mkProxyState
		let proxyparams = Proxy.ProxyParams
			{ Proxy.proxyMethods = mkProxyMethods
			, Proxy.proxyState = proxystate
			, Proxy.proxyServerMode = connectionServerMode connparams
			, Proxy.proxyClientSide = Proxy.ClientSide proxyfromclientrunst proxyfromclientconn
			, Proxy.proxyUUID = proxyConnectionRemoteUUID proxyconn
			, Proxy.proxySelector = proxyConnectionSelector proxyconn
			, Proxy.proxyConcurrencyConfig = proxyConnectionConcurrency proxyconn
			, Proxy.proxyClientProtocolVersion = connectionProtocolVersion connparams
			}
		let proxy mrequestmessage = case mrequestmessage of
			Just requestmessage -> do
				Proxy.proxyRequest proxydone proxyparams
					requestcomplete requestmessage protoerrhandler
			Nothing -> return ()
		protoerrhandler proxy $
			liftIO $ runNetProto proxyfromclientrunst proxyfromclientconn $
				P2P.net P2P.receiveMessage
	
	let closebothsides = do
		liftIO $ closeConnection proxyfromclientconn
		liftIO $ closeConnection clientconn

	let releaseconn connstillusable = do
		atomically $ void $ tryPutTMVar relv $ do
			unless connstillusable
				closebothsides
			r <- liftIO $ wait asyncworker
			when connstillusable
				closebothsides
			if connstillusable
				then liftIO $ do
					now <- getPOSIXTime
					evicted <- atomically $ putProxyConnectionPool proxypool proxyconnectionpoolsize connparams $
						proxyconn { proxyConnectionLastUsed = now }
					mapM_ (closeProxyConnection proxyrunnermap) evicted
				else closeProxyConnection proxyrunnermap proxyconn
			either throwM return r
				
	return $ Right $ P2PConnectionPair
		{ clientRunState = clientrunst
		, clientP2PConnection = clientconn
		, serverP2PConnection = proxyfromclientconn
		, releaseP2PConnection = releaseconn True
		, closeP2PConnection = releaseconn False
		}
  where
	protoerrhandler cont a = a >>= \case
		Left _ -> proxyConnectionCloser proxyconn
		Right v -> cont v
	
	proxydone = return ()
	
	requestcomplete () = return ()

-- Close a proxy connection, and release resources used by the remote.
closeProxyConnection :: ProxyRunnerMap -> ProxyConnection -> IO ()
closeProxyConnection proxyrunnermap proxyconn = do
	runner <- getProxyRunner proxyrunnermap (proxyConnectionKey proxyconn)
	void $ proxyRunner runner $ do
		proxyConnectionCloser proxyconn
		quiesce True
	atomically $ do
		(maker, m) <- takeTMVar proxyrunnermap
		let !m' = M.delete (proxyConnectionKey proxyconn) m
		putTMVar proxyrunnermap (maker, m')

openedProxyConnection
	:: UUID
	-> String
	-> Proxy.ProxySelector
	-> Annex ()
	-> Proxy.ConcurrencyConfig
	-> ProxyConnectionKey
	-> Annex ProxyConnection
openedProxyConnection u desc selector closer concurrency k = do
	now <- liftIO getPOSIXTime
	fastDebug "P2P.Http" ("Opened proxy connection to " ++ desc)
	return $ ProxyConnection u selector closer' concurrency now k
  where
	closer' = do
		fastDebug "P2P.Http" ("Closing proxy connection to " ++ desc)
		closer
		fastDebug "P2P.Http" ("Closed proxy connection to " ++ desc)

openProxyConnectionToRemote
	:: P2P.ProtocolVersion
	-> P2P.Bypass
	-> Remote
	-> ProxyConnectionKey
	-> Annex ProxyConnection
openProxyConnectionToRemote clientmaxversion bypass remote k = do
	remoteside <- proxyRemoteSide clientmaxversion bypass remote
	concurrencyconfig <- Proxy.noConcurrencyConfig
	openedProxyConnection (Remote.uuid remote)
		("remote " ++ Remote.name remote)
		(Proxy.singleProxySelector remoteside)
		(Proxy.closeRemoteSide remoteside)
		concurrencyconfig
		k

type ClusterConcurrency = Int

openProxyConnectionToCluster
	:: P2P.ProtocolVersion
	-> P2P.Bypass
	-> ClusterUUID
	-> ClusterConcurrency
	-> ProxyConnectionKey
	-> Annex ProxyConnection
openProxyConnectionToCluster clientmaxversion bypass clusteruuid concurrency k = do
	(proxyselector, closenodes) <-
		clusterProxySelector clusteruuid clientmaxversion bypass
	concurrencyconfig <- Proxy.mkConcurrencyConfig concurrency
	openedProxyConnection (fromClusterUUID clusteruuid)
		("cluster " ++ fromUUID (fromClusterUUID clusteruuid))
		proxyselector closenodes concurrencyconfig k

-- Returns any older ProxyConnection that was evicted from the pool.
putProxyConnectionPool
	:: TMVar ProxyConnectionPool
	-> ProxyConnectionPoolSize
	-> ConnectionParams
	-> ProxyConnection
	-> STM [ProxyConnection]
putProxyConnectionPool proxypool maxsz connparams conn = do
	(sz, m) <- takeTMVar proxypool
	let ((sz', m'), evicted) = putProxyConnectionPool' maxsz k conn sz m
	let ((sz'', m''), evicted') = if sz' > maxsz
		then removeOldestProxyConnectionPool (sz', m')
		else ((sz', m'), Nothing)
	putTMVar proxypool (sz'', m'')
	return $ catMaybes [evicted, evicted']
  where
	k = mkProxyConnectionKey connparams

putProxyConnectionPool' :: Ord k => Integer -> k -> c -> Integer -> M.Map k [c] -> ((Integer, M.Map k [c]), Maybe c)
putProxyConnectionPool' maxsz k conn sz m =
	case M.lookup k m of
		Nothing -> ((succ sz, M.insert k [conn] m), Nothing)
		Just [] -> ((succ sz, M.insert k [conn] m), Nothing)
		Just cs -> if sz >= maxsz
			then ((sz, M.insert k (conn : dropFromEnd 1 cs) m), lastMaybe cs)
			else ((succ sz, M.insert k (conn : cs) m), Nothing)

removeOldestProxyConnectionPool :: ProxyConnectionPool -> (ProxyConnectionPool, Maybe ProxyConnection)
removeOldestProxyConnectionPool (sz, m) = 
	((pred sz, m'), snd <$> headMaybe l)
  where
	m' = M.fromListWith (++) $ map (\(k', v) -> (k', [v])) (drop 1 l)
	l = sortOn (proxyConnectionLastUsed . snd) $
		concatMap (\(k', pl) -> map (k', ) pl) $
			M.toList m

getProxyConnectionPool
	:: TMVar ProxyConnectionPool
	-> ProxyConnectionKey
	-> STM (Maybe ProxyConnection)
getProxyConnectionPool proxypool k = do
	(sz, m) <- takeTMVar proxypool
	case M.lookup k m of
		Just (c:cs) -> do
			putTMVar proxypool (sz-1, M.insert k cs m)
			return (Just c)
		_ -> do
			putTMVar proxypool (sz, m)
			return Nothing

