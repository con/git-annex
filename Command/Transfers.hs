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
import Messages.Concurrent
import Utility.ThreadScheduler
import Utility.Metered
import Annex.Concurrent
import Database.Keys
import Git.FilePath

import qualified Data.Map as M
import Control.Concurrent.STM
import Control.Concurrent.Async

cmd :: Command
cmd = noCommit $ withAnnexOptions [jsonOptions, jsonProgressOption] $
	command "transfers" SectionQuery
		"display transfers"
		paramNothing (seek <$$> optParser)

data TransfersOptions = TransfersOptions
	{ localFilenames :: Bool 
	}

optParser :: CmdParamsDesc -> Parser TransfersOptions
optParser _ = TransfersOptions
	<$> switch
		( long "localfilenames"
		<> short 'l'
		<> help "display local filenames, not remote filenames"
		)

seek :: TransfersOptions -> CommandSeek
seek o = withConcurrentOutput $ do
	when (localFilenames o)
		updateDatabase
	rs <- remoteList
	let remotemap = M.fromList $ zip (map uuid rs) rs
	go remotemap M.empty
  where
	go remotemap transfermap = do
		l <- getTransfers
		new <- forM l $ \(t, ti) -> do
			case M.lookup t transfermap of
				Nothing -> startone remotemap t ti
				Just v -> return (t, v)
		let newmap = M.fromList new
		forM_ (M.toList transfermap) $ \(t, (endvar, tid)) -> 
			unless (M.member t newmap) $ do
				liftIO $ atomically $ putTMVar endvar ()
				void $ join $ liftIO $ wait tid
		liftIO $ threadDelaySeconds (SecondsDelay 1)
		go remotemap newmap
	
	startone remotemap t ti = do
		endvar <- liftIO newEmptyTMVarIO
		a <- forkState $ 
			withMessageState $ \s ->
				inOwnConsoleRegion s $
					includeCommandAction $
						start o t ti endvar remotemap
		tid <- liftIO $ async a
		return (t, (endvar, tid))

start :: TransfersOptions -> Transfer -> TransferInfo -> TMVar () -> M.Map UUID Remote -> CommandStart
start o t ti endvar remotemap = do
	af <- if localFilenames o
		then headMaybe <$> getAssociatedFiles k >>= \case
			Just topf -> relaf =<< fromRepo (fromTopFilePath topf)
			Nothing -> pure $ AssociatedFile Nothing
		else pure $ associatedFile ti
	let ai = ActionItemAssociatedFile af k
	startingNoMessage ai $ do
		showStartMessage (StartMessage verb ai si)
		showNote $ UnquotedString $ fromto ++ " " ++ remotename
		maybeAddJSONField "remote-uuid" (transferUUID t)
		(tfile, _, _) <- fromRepo $ transferFileAndLockFile t
		metered Nothing k Nothing $ \_ p ->
			watchSizeWith (getprogress tfile) p $
				const waitend

		showEnd "done"
		next $ return True
  where
  	k = transferKey t
	
	si = SeekInput []
  	
	verb = case transferDirection t of
		Upload -> "send"
		Download -> "receive"
	
	fromto = case transferDirection t of
		Upload -> "to"
		Download -> "from"
	
	remotename =
		maybe (fromUUID (transferUUID t)) name $
			M.lookup (transferUUID t) remotemap
	
	waitend = 
		liftIO $ atomically $ takeTMVar endvar
	
	relaf f = AssociatedFile . Just <$> liftIO (relPathCwdToFile f)

	getprogress tfile = readTransferInfoFile Nothing tfile
		>>= return . \case
			Just ti' -> maybe zeroBytesProcessed toBytesProcessed
				(bytesComplete ti')
			Nothing -> zeroBytesProcessed
