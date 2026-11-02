{- git-annex command
 -
 - Copyright 2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE OverloadedStrings #-}

module Command.Transfers where

import Command
import Types.Transfer
import Logs.Transfer
import Remote
import Messages.Progress
import Utility.ThreadScheduler

import qualified Data.Map as M
import Control.Concurrent.STM

cmd :: Command
cmd = noCommit $ withAnnexOptions [jsonOptions, jsonProgressOption, jobsOption] $
	command "transfers" SectionQuery
		"display transfers"
		paramNothing (withParams (withNothing seek))

seek :: CommandSeek
seek = startConcurrency commandStages $ do
	rs <- remoteList
	let remotemap = M.fromList $ zip (map uuid rs) rs
	go remotemap M.empty
  where
	go remotemap transfermap = do
		l <- getTransfers
		new <- forM l $ \(t, ti) -> do
			case M.lookup t transfermap of
				Nothing -> do
					endvar <- liftIO newEmptyTMVarIO
					commandAction $
						start t ti endvar remotemap
					return (t, endvar)
				Just endvar -> return (t, endvar)
		let newmap = M.fromList new
		forM_ (M.toList transfermap) $ \(t, endvar) -> 
			unless (M.member t newmap) $
				liftIO $ atomically $ putTMVar endvar ()
		liftIO $ threadDelaySeconds (SecondsDelay 1)
		go remotemap newmap

start :: Transfer -> TransferInfo -> TMVar () -> M.Map UUID Remote -> CommandStart
start t ti endvar remotemap = startingNoMessage ai $ do
	showStartMessage (StartMessage verb ai si)
	case M.lookup (transferUUID t) remotemap of
		Just r -> showNote $ UnquotedString $ fromto ++ " " ++ name r
		Nothing -> noop
	case transferDirection t of
		Download -> do
			o <- fromRepo $ gitAnnexTmpObjectLocation k
			meteredFile o Nothing k $ const waitend
		Upload -> waitend
	showEnd "done"
	next $ return True
  where
  	k = transferKey t
	ai = ActionItemAssociatedFile (associatedFile ti) k
	si = SeekInput []
  	verb = case transferDirection t of
		Upload -> "send"
		Download -> "receive"
	fromto = case transferDirection t of
		Upload -> "to"
		Download -> "from"
	waitend = 
		liftIO $ atomically $ takeTMVar endvar
