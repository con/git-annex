{- Interface to libmagic
 -
 - Copyright 2019-2026 Joey Hess <id@joeyh.name>
 -
 - Licensed under the GNU AGPL version 3 or higher.
 -}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE CPP #-}

module Annex.Magic (
	Magic,
	MimeType,
	MimeEncoding,
	initMagicMime,
	getMagicMime,
	getMagicMimeType,
	getMagicMimeEncoding,
	parseMagicMime,
	magicFileLocation,
) where

import Common
import Types.Mime
import Control.Monad.IO.Class
import qualified Data.ByteString as B
import Data.Char
import Utility.Env
import Annex.Path

#ifdef WITH_MAGICMIME
import Magic
import qualified Data.List.NonEmpty as NE
import qualified System.OsString.Internal as OS
#else
type Magic = ()
#endif

magicFileLocation :: IO (Maybe OsPath)
magicFileLocation = 
	gitAnnexInstallDir >>= \case
		Nothing -> do
#ifndef mingw32_HOST_OS
			pure Nothing
#else
			-- On windows, the magic file is
			-- in ../share/misc/ relative
			-- to the program.
			pd <- takeDirectory <$> programPath
			use $
				pd
					</> literalOsPath ".."
					</> literalOsPath "share"
					</> literalOsPath "misc"
					</> literalOsPath "magic.mgc"
#endif
		Just d -> use $
			d
				</> literalOsPath "magic"
				</> literalOsPath "magic.mgc"
  where
	use p = Just . maybe p toOsPath <$> getEnv "MAGIC"

initMagicMime :: IO (Maybe Magic)
#ifdef WITH_MAGICMIME
initMagicMime = catchMaybeIO $ do
	m <- magicOpen [MagicMime]
	magicFileLocation >>= \case
		Nothing -> magicLoadDefault m
		Just d -> do
			p <- OS.encodeFS $ fromOsPath d
			magicLoad m $ NE.singleton p
	return m
#else
initMagicMime = return Nothing
#endif

getMagicMime :: Magic -> OsPath -> IO (Maybe (MimeType, MimeEncoding))
#ifdef WITH_MAGICMIME
getMagicMime m f = Just . parseMagicMime
	<$> (magicFile m =<< OS.encodeFS (fromOsPath f))
#else
getMagicMime _ _ = return Nothing
#endif

parseMagicMime :: B.ByteString -> (MimeType, MimeEncoding)
parseMagicMime b = (decodeBS mimetype, decodeBS mimeencoding)
  where
	(mimetype, rest) = B.break (== semicolon) b
	mimeencoding = fromMaybe mempty (B.stripPrefix "; charset=" rest)
	semicolon = fromIntegral (ord ';')

getMagicMimeType :: MonadIO m => Magic -> OsPath -> m (Maybe MimeType)
getMagicMimeType m f = liftIO $ fmap fst <$> getMagicMime m f

getMagicMimeEncoding :: MonadIO m => Magic -> OsPath -> m(Maybe MimeEncoding)
getMagicMimeEncoding m f = liftIO $ fmap snd <$> getMagicMime m f
