{- P2P protocol over HTTP, internal types
 -
 - Copyright 2024-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

module P2P.Http.Types.Internal where

import Annex.Common
import qualified Annex
import P2P.Http.Types
import qualified P2P.Protocol as P2P
import P2P.IO
import Types.WorkerPool
import qualified P2P.Proxy as Proxy
import Utility.LRU

import Servant (IsSecure)
import qualified Data.Map.Strict as M
import Control.Concurrent.Async
import Control.Concurrent.STM
import Data.Unique

data P2PHttpServerState = P2PHttpServerState
	{ servedRepos :: M.Map UUID PerRepoServerState
	, serverShutdownCleanup :: IO ()
	, updateRepos :: UpdateRepos
	}

type UpdateRepos = P2PHttpServerState -> IO P2PHttpServerState

instance Monoid P2PHttpServerState where
	mempty = P2PHttpServerState
		{ servedRepos = mempty
		, serverShutdownCleanup = noop
		, updateRepos = const mempty
		}

instance Semigroup P2PHttpServerState where
	a <> b = P2PHttpServerState
		{ servedRepos = servedRepos a <> servedRepos b
		, serverShutdownCleanup = do
			serverShutdownCleanup a
			serverShutdownCleanup b
		, updateRepos = \st -> do
			a' <- updateRepos a st
			b' <- updateRepos b st
			return (a' <> b')
		}

data PerRepoServerState = PerRepoServerState
	{ acquireP2PConnection :: AcquireP2PConnection
	, annexWorkerPool :: AnnexWorkerPool
	, annexState :: TMVar Annex.AnnexState
	, annexRead :: Annex.AnnexRead
	, getServerMode :: GetServerMode
	, openLocks :: TMVar (M.Map LockID Locker)
	, lockedFilesQSem :: LockedFilesQSem
	, branchChangesInProgress :: TMVar Bool
	}

type AnnexWorker = (Annex.AnnexState, Annex.AnnexRead)

type AnnexWorkerPool = TMVar (WorkerPool (AnnexWorker, Unique))

type GetServerMode = IsSecure -> Maybe Auth -> ServerMode

type LockedFilesQSem = TMVar Integer

mkLockedFilesQSem :: Maybe Integer -> IO LockedFilesQSem
mkLockedFilesQSem = newTMVarIO . fromMaybe 100

data ServerMode
	= ServerMode
		{ serverMode :: P2P.ServerMode
		, unauthenticatedLockingAllowed :: Bool
		, authenticationAllowed :: Bool
		}
	| CannotServeRequests

mkPerRepoServerState :: AcquireP2PConnection -> AnnexWorkerPool -> TMVar Annex.AnnexState -> Annex.AnnexRead -> GetServerMode -> LockedFilesQSem -> IO PerRepoServerState
mkPerRepoServerState acquireconn annexworkerpool annexstate annexread getservermode lockedfilesqsem = PerRepoServerState
	<$> pure acquireconn
	<*> pure annexworkerpool
	<*> pure annexstate
	<*> pure annexread
	<*> pure getservermode
	<*> newTMVarIO mempty
	<*> pure lockedfilesqsem
	<*> newEmptyTMVarIO

data ActionClass = ReadAction | WriteAction | RemoveAction | LockAction
	deriving (Eq)

data ConnectionParams = ConnectionParams
	{ connectionProtocolVersion :: P2P.ProtocolVersion
	, connectionServerUUID :: UUID
	, connectionClientUUID :: UUID
	, connectionBypass :: [UUID]
	, connectionServerMode :: P2P.ServerMode
	, connectionWaitVar :: Bool
	}
	deriving (Show, Eq, Ord)

data ConnectionProblem
	= ConnectionFailed String
	| TooManyConnections
	deriving (Show, Eq)

type AcquireP2PConnection
	= AnnexActionRunner
	-> ConnectionParams
	-> IO (Either ConnectionProblem P2PConnectionPair)

data P2PConnectionPair = P2PConnectionPair
	{ clientRunState :: RunState
	, clientP2PConnection :: P2PConnection
	, serverP2PConnection :: P2PConnection
	, releaseP2PConnection :: IO ()
	-- ^ Releases a P2P connection, which can be reused for other
	-- requests.
	, closeP2PConnection :: IO ()
	-- ^ Closes a P2P connection, which is in a state where it is no
	-- longer usable.
	}

data Locker = Locker
	{ lockerThread :: Async ()
	, lockerVar :: TMVar Bool
	-- ^ Left empty until the thread has taken the lock
	-- (or failed to do so), then True while the lock is held,
	-- and setting to False causes the lock to be released.
	, lockerTimeoutDisable :: TMVar ()
	-- ^ Until this is filled, the lock will be subject to timeout.
	-- Once filled the lock will remain held until explicitly dropped.
	}

data AnnexActionRunner
	-- Number of concurrent Annex actions is bounded by the size of the 
	-- worker pool
	= WorkerPoolRunner
	-- When using this, must enforce bounds first
	| RequestRunner

-- | Each call makes a new AnnexWorker state.
type AnnexWorkerMaker = IO AnnexWorker

type ProxyRunnerMap = TMVar (AnnexWorkerMaker, M.Map ProxyConnectionKey ProxyRunner)

data ProxyRunner = ProxyRunner (TMVar Annex.AnnexState) Annex.AnnexRead

type ProxyConnectionPool = LRU ProxyConnectionKey ProxyConnection

mkProxyConnectionPool :: IO (TMVar ProxyConnectionPool)
mkProxyConnectionPool = newTMVarIO emptyLRU

type ProxyConnectionPoolSize = Int

-- A key that can be used to look up a ProxyConnection.
-- The Unique allows storing multiple otherwise identical ones in a LRU.
type ProxyConnectionKey =
	( (UUID, UUID, [UUID], P2P.ProtocolVersion)
	, Maybe Unique
	)

mkProxyConnectionKey :: ConnectionParams -> Maybe Unique -> ProxyConnectionKey
mkProxyConnectionKey connparams unique =
	(
		( connectionServerUUID connparams
		, connectionClientUUID connparams
		, connectionBypass connparams
		, connectionProtocolVersion connparams
		)
	, unique
	)

data ProxyConnection = ProxyConnection
	{ proxyConnectionRemoteUUID :: UUID
	, proxyConnectionSelector :: Proxy.ProxySelector
	, proxyConnectionCloser :: Annex ()
	, proxyConnectionConcurrency :: Proxy.ConcurrencyConfig
	, proxyConnectionKey :: ProxyConnectionKey
	}

instance Show ProxyConnection where
	show pc = unwords
		[ "ProxyConnection"
		, show (proxyConnectionRemoteUUID pc)
		]

