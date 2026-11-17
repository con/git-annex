{- P2P protocol over HTTP, lockers
 -
 - https://git-annex.branchable.com/design/p2p_protocol_over_http/
 -
 - Copyright 2024-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE BangPatterns #-}

module P2P.Http.Locker where

import Annex.Common
import P2P.Http.Types
import P2P.Http.Types.Internal
import Annex.UUID
import Types.NumCopies
import Utility.ThreadScheduler
import Utility.HumanTime

import qualified Data.Map.Strict as M
import Control.Concurrent.Async
import Control.Concurrent.STM

mkLocker :: (IO (Maybe a)) -> (a -> IO ()) -> IO (Maybe (Locker, LockID))
mkLocker lock unlock = do
	lv <- newEmptyTMVarIO
	timeoutdisablev <- newEmptyTMVarIO
	timeouttid <- async $ whenM (atomically $ readTMVar lv) $ do
		threadDelaySeconds $ SecondsDelay $ fromIntegral $
			durationSeconds p2pDefaultLockContentRetentionDuration
		atomically (tryReadTMVar timeoutdisablev) >>= \case
			Nothing -> void $ atomically $
				writeTMVar lv False
			Just () -> noop
	let setlocked = putTMVar lv
	locktid <- async $ lock >>= \case
		Nothing ->
			atomically $ setlocked False
		Just st -> do
			atomically $ setlocked True
			atomically $ do
				v <- takeTMVar lv
				if v
					then retry
					else setlocked False
			unlock st
	locksuccess <- atomically $ readTMVar lv
	if locksuccess
		then do
			tid <- async $ do
				wait locktid
				cancel timeouttid
			lckid <- B64UUID <$> genUUID
			return (Just (Locker tid lv timeoutdisablev, lckid))
		else do
			wait locktid
			return Nothing

storeLock :: LockID -> Locker -> PerRepoServerState -> IO ()
storeLock lckid locker st = atomically $ do
	m <- takeTMVar (openLocks st)
	let !m' = M.insert lckid locker m
	putTMVar (openLocks st) m'

keepingLocked :: LockID -> PerRepoServerState -> IO ()
keepingLocked lckid st = do
	m <- atomically $ readTMVar (openLocks st)
	case M.lookup lckid m of
		Nothing -> return ()
		Just locker ->
			atomically $ void $ 
				tryPutTMVar (lockerTimeoutDisable locker) ()

dropLock :: LockID -> PerRepoServerState -> IO ()
dropLock lckid st = do
	v <- atomically $ do
		m <- takeTMVar (openLocks st)
		let (mlocker, !m') =
			M.updateLookupWithKey (\_ _ -> Nothing) lckid m
		putTMVar (openLocks st) m'
		case mlocker of
			Nothing -> return Nothing
			-- Signal to the locker's thread that it can
			-- release the lock.
			Just locker -> do
				_ <- swapTMVar (lockerVar locker) False
				return (Just locker)
	case v of
		Nothing -> return ()
		Just locker -> wait (lockerThread locker)
