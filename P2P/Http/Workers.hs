{- P2P protocol over HTTP, workers
 -
 - https://git-annex.branchable.com/design/p2p_protocol_over_http/
 -
 - Copyright 2024-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

module P2P.Http.Workers where

import Annex.Common
import qualified Annex
import P2P.Http.Types.Internal
import Types.WorkerPool
import Annex.WorkerPool
import Annex.Action
import Annex.Concurrent
import Types.Concurrency
import CmdLine.Action (startConcurrency', startConcurrency)
import qualified Git
import Utility.LRU

import Control.Concurrent.Async
import Control.Concurrent.STM
import Data.Unique
import qualified Data.Map.Strict as M

serverStages :: UsedStages
serverStages = transferStages

-- quiesceAnnexWorker calls stopCoProcesses, which stops helper processes
-- that are in resource pools set up by dupState and shared with other
-- AnnexWorkers. So this must not use dupState.
mkAnnexWorkerMaker :: Git.Repo -> IO AnnexWorkerMaker
mkAnnexWorkerMaker r = do
	maker <- Annex.newMaker r
	return $ do
		strd <- maker
		((), strd') <- Annex.run strd $ do
			setConcurrency $ ConcurrencyCmdLine $ Concurrent 1
			startConcurrency serverStages noop
		return strd'

withAnnexWorkerPool
	:: Maybe Concurrency
	-> Maybe Cpus
	-> AnnexWorkerLimit
	-> AnnexWorkerMaker
	-> (AnnexWorkerPool -> ProxyRunnerMap -> Annex a)
	-> Annex a
withAnnexWorkerPool mconc mcpus workerlimit maker a = do
	maybe noop setCpus mcpus
	maybe noop (setConcurrency . ConcurrencyCmdLine) mconc
	startConcurrency' serverStages $ \nworkers ->
		Annex.getState Annex.workers >>= \case
			Nothing -> giveup "Use --jobs or set annex.jobs to configure the number of worker threads."
			Just wpv -> go wpv nworkers
  where
	stages = transferStages
	go wpv nworkers = case workerlimit of
		NoWorkerLimit -> use $ atomically $ readTMVar wpv
		WorkerLimit {} -> do
			liftIO $ setAnnexWorkerLimit workerlimit nworkers
			use (allocateWorkerPoolM maker nworkers stages)
				`finally` quiesce True
	use mkp = do
		tp <- liftIO $ taggedWorkerPool =<< mkp
		awp <- liftIO $ newTMVarIO tp
		proxyrunnermap <- liftIO $ newTMVarIO (maker, mempty)
		a awp proxyrunnermap

inAnnexWorker :: AnnexWorkerLimit -> AnnexWorkerPool -> Annex a -> IO (Either SomeException a)
inAnnexWorker workerlimit poolv annexaction =
	allocateAnnexWorker workerlimit (waitStartWorkerSlot poolv)
		>>= inAnnexWorker' workerlimit poolv annexaction

inAnnexWorkerNonBlocking :: AnnexWorkerLimit -> AnnexWorkerPool -> Annex a -> IO (Maybe (Either SomeException a))
inAnnexWorkerNonBlocking workerlimit poolv annexaction =
	allocateAnnexWorkerNonBlocking workerlimit (waitStartWorkerSlot poolv) >>= \case
		Nothing -> return Nothing
		Just v -> Just <$> inAnnexWorker' workerlimit poolv annexaction v

inAnnexWorker'
	:: AnnexWorkerLimit
	-> AnnexWorkerPool
	-> Annex a
	-> ((AnnexWorker, Unique), WorkerStage)
	-> IO (Either SomeException a)
inAnnexWorker' workerlimit poolv annexaction ((workerstrd, workerid), workerstage) = do
	resv <- newEmptyTMVarIO
	aid <- async $ do
		(res, strd) <- Annex.run workerstrd annexaction
		atomically $ putTMVar resv res
		return (strd, workerid)
	atomically $ do
		pool <- takeTMVar poolv
		let !pool' = addWorkerPool (ActiveWorker aid workerstage) pool
		putTMVar poolv pool'
	
	(res, workerstrdid) <- waitCatch aid >>= \case
		Right strdid -> do
			r <- atomically $ takeTMVar resv
			return (Right r, strdid)
		Left err -> return (Left err, (workerstrd, workerid))
	
	atomically $ do
		deallocateAnnexWorker workerlimit workerstrd workerid
		pool <- takeTMVar poolv
		let !pool' = deactivateWorker pool aid workerstrdid
		putTMVar poolv pool'

	return res

data AnnexWorkerLimit
	= NoWorkerLimit
	| WorkerLimit 
		{ workerLimit :: TMVar (Int, WarmWorkers)
		, workerLimitName :: Maybe String
		}

-- Workers that are not in use, but that have been warmed up: They have
-- opened file handles, started helper processes, etc.
type WarmWorkers = LRU Unique AnnexWorker

mkAnnexWorkerLimit :: IO AnnexWorkerLimit
mkAnnexWorkerLimit = WorkerLimit 
	<$> newTMVarIO (1, emptyLRU)
	<*> pure Nothing

setAnnexWorkerLimitName :: String -> AnnexWorkerLimit -> AnnexWorkerLimit
setAnnexWorkerLimitName name workerlimit@(WorkerLimit {}) =
	workerlimit { workerLimitName = Just name }
setAnnexWorkerLimitName _ workerlimit = workerlimit

setAnnexWorkerLimit :: AnnexWorkerLimit -> Int -> IO ()
setAnnexWorkerLimit WorkerLimit { workerLimit = v } nworkers =
	atomically $ do
		(_, lru) <- takeTMVar v
		putTMVar v (nworkers, lru)
setAnnexWorkerLimit NoWorkerLimit _ = noop

describeAnnexWorker :: AnnexWorkerLimit -> Unique -> String
describeAnnexWorker (WorkerLimit { workerLimitName = Just name }) workerid =
	name ++ " " ++ descibeAnnexWorker' workerid
describeAnnexWorker _ workerid =
	descibeAnnexWorker' workerid

descibeAnnexWorker' :: Unique -> String
descibeAnnexWorker' workerid = "#" ++ show (hashUnique workerid)

{- Allocate a new annex worker.
 - If necessary, first quiesces the least recently used one.
 -
 - Blocks when the server is too busy.
 -}
allocateAnnexWorker
	:: AnnexWorkerLimit
	-> STM ((AnnexWorker, Unique), WorkerStage)
	-> IO ((AnnexWorker, Unique), WorkerStage)
allocateAnnexWorker workerlimit a = 
	atomically (allocateAnnexWorker' workerlimit a)
		>>= allocatedAnnexWorker workerlimit a

allocateAnnexWorkerNonBlocking
	:: AnnexWorkerLimit
	-> STM ((AnnexWorker, Unique), WorkerStage)
	-> IO (Maybe ((AnnexWorker, Unique), WorkerStage))
allocateAnnexWorkerNonBlocking workerlimit a = do
	r <- atomically $
		(Just <$> allocateAnnexWorker' workerlimit a)
			`orElse`
		return Nothing
	case r of
		Nothing -> return Nothing
		Just r' -> Just <$> allocatedAnnexWorker workerlimit a r'

allocateAnnexWorker'
	:: AnnexWorkerLimit
	-> STM ((AnnexWorker, Unique), WorkerStage)
	-> STM (Either (Unique, AnnexWorker) ((AnnexWorker, Unique), WorkerStage))
allocateAnnexWorker' NoWorkerLimit a = Right <$> a
allocateAnnexWorker' (WorkerLimit { workerLimit = v }) a = do
	(n, warm) <- takeTMVar v
	if n < 1
		then case popLRU warm of
			(warm', Just toquiesce) -> do
				putTMVar v (n-1, warm')
				return $ Left toquiesce
			_ -> retry
		else do
			res@((_, workerid), _) <- a
			putTMVar v (n-1, removeLRU warm workerid)
			return $ Right res

allocatedAnnexWorker
	:: AnnexWorkerLimit
	-> STM ((AnnexWorker, Unique), WorkerStage)
	-> Either (Unique, AnnexWorker) ((AnnexWorker, Unique), WorkerStage)
	-> IO ((AnnexWorker, Unique), WorkerStage)
allocatedAnnexWorker workerlimit a r =
	observe reportworkerid $ case r of
		Right res -> return res
		Left toquiesce -> do
			quiesceAnnexWorker workerlimit toquiesce
			atomically $ postQueusceAnnexWorker workerlimit a
  where
	reportworkerid ((_, workerid), _) =
		debug "P2P.Http" $ "Using worker "
			++ describeAnnexWorker workerlimit workerid

postQueusceAnnexWorker
	:: AnnexWorkerLimit
	-> STM ((AnnexWorker, Unique), WorkerStage)
	-> STM ((AnnexWorker, Unique), WorkerStage)
postQueusceAnnexWorker (WorkerLimit { workerLimit = v }) a = do
	(n, warm) <- takeTMVar v
	res@((_, workerid), _) <- a
	putTMVar v (n, removeLRU warm workerid)
	return res
postQueusceAnnexWorker NoWorkerLimit a = a

-- Called after allocateAnnexWorker has allocated a worker,
-- and it is done being used.
deallocateAnnexWorker :: AnnexWorkerLimit -> AnnexWorker -> Unique -> STM ()
deallocateAnnexWorker NoWorkerLimit _ _ = noop
deallocateAnnexWorker (WorkerLimit { workerLimit = v }) worker workerid = do
	(n, warm) <- takeTMVar v
	let warm' = addLRU warm workerid worker
	putTMVar v (n+1, warm')

-- Make an Annex worker no longer be warmed up, by stopping all
-- helper processes, closing file handles, etc.
quiesceAnnexWorker :: AnnexWorkerLimit -> (Unique, AnnexWorker) -> IO ()
quiesceAnnexWorker workerlimit (workerid, workerstrd) = do
	debug "P2P.Http" $ "Quiesceing worker "
		++ describeAnnexWorker workerlimit workerid
	-- This discards the changed state, so the only things it can
	-- safely do are those that do not alter state.
	res <- tryNonAsync $ Annex.eval workerstrd $
		quiesce True 
	case res of
		Left ex -> debug "P2P.Http" $ "Quiesceing worker "
			++ describeAnnexWorker workerlimit workerid
			++ " failed: " ++ show ex
		Right () -> return ()

-- When there is a WorkerLimit, handleRequestAnnex may warm up
-- an Annex state, starting helper processes, opening file handles etc.
-- Quiesce it here to avoid one such Annex state per served repository
-- remaining warmed up.
--
-- With NoWorkerLimit, there is no need to quiesce here, because there
-- is only one such Annex state.
quiesceRequestAnnex :: AnnexWorkerLimit -> Annex ()
quiesceRequestAnnex NoWorkerLimit = noop
quiesceRequestAnnex (WorkerLimit {}) = quiesce True

handleRequestAnnex :: PerRepoServerState -> Annex a -> IO (Either SomeException a)
handleRequestAnnex st = handleRequestAnnex' (annexState st) (annexRead st)

handleRequestAnnex' :: TMVar Annex.AnnexState -> Annex.AnnexRead -> Annex a -> IO (Either SomeException a)
handleRequestAnnex' stv rd a = do
	ast <- atomically $ readTMVar stv
	let astdup = dupState' ast

	(res, (astdup', _)) <- Annex.run (astdup, rd) $ 
		tryNonAsync a
	
	ast' <- atomically $ takeTMVar stv
	((), (ast'', _)) <- Annex.run (ast', rd) $ mergeState astdup'
	atomically $ putTMVar stv ast''

	return res

annexActionRunner :: AnnexActionRunner -> AnnexWorkerLimit -> AnnexWorkerPool -> TMVar Annex.AnnexState -> Annex.AnnexRead -> Annex a -> IO (Either SomeException a)
annexActionRunner WorkerPoolRunner workerlimit workerpool _ _ =
	inAnnexWorker workerlimit workerpool
annexActionRunner RequestRunner _ _ st rd =
	handleRequestAnnex' st rd

getProxyRunner :: ProxyRunnerMap -> ProxyConnectionKey -> IO ProxyRunner
getProxyRunner v k = do
	v'@(maker, m) <- atomically (takeTMVar v)
	case M.lookup k m of
		Just runner -> do
			atomically $ putTMVar v v'
			return runner
		Nothing -> do
			(st, rd) <- maker
				`onException` atomically (putTMVar v v')
			stv <- newTMVarIO st
			let runner = ProxyRunner stv rd
			atomically $ putTMVar v (maker, M.insert k runner m)
			return runner

proxyRunner :: ProxyRunner -> Annex a -> IO (Either SomeException a)
proxyRunner (ProxyRunner stv rd) = handleRequestAnnex' stv rd
