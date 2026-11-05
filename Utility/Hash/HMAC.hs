{- Convenience wrapper for HMACs
 -
 - Copyright 2013-2026 Joey Hess <id@joeyh.name>
 -
 - License: BSD-2-clause
 -}

{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE OverloadedStrings #-}

module Utility.Hash.HMAC (
	Mac(..),
	calcMac,
	props_macs_stable,
) where

import Utility.Hash.Types
import qualified Data.ByteString as S
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Botan.Low.MAC
import Botan.Low.Hash hiding (HashDigest)
import System.IO.Unsafe (unsafePerformIO)

data Mac = HmacSha1 | HmacSha224 | HmacSha256 | HmacSha384 | HmacSha512
	deriving (Eq)

calcMac
	:: (HashDigest -> t) -- ^ applied to MAC'ed message
	-> Mac               -- ^ MAC
	-> S.ByteString      -- ^ secret key
	-> S.ByteString      -- ^ message
	-> t
calcMac f mac = case mac of
	HmacSha1   -> use SHA1
	HmacSha224 -> use SHA224
	HmacSha256 -> use SHA256
	HmacSha384 -> use SHA384
	HmacSha512 -> use SHA512
  where
	use alg k m = unsafePerformIO $ do
		maccer <- macInit (hmac alg)
		macSetKey maccer k
		macUpdate maccer m
		auth <- macFinal maccer
		return (f (HashDigest auth))

-- Check that all the MACs continue to produce the same.
props_macs_stable :: [(String, Bool)]
props_macs_stable = map (\(desc, mac, result) -> (desc ++ " stable", calcMac digestToHash mac key msg == result))
	[ ("HmacSha1", HmacSha1, "46b4ec586117154dacd49d664e5d63fdc88efb51")
	, ("HmacSha224", HmacSha224, "4c1f774863acb63b7f6e9daa9b5c543fa0d5eccf61e3ffc3698eacdd")
	, ("HmacSha256", HmacSha256, "f9320baf0249169e73850cd6156ded0106e2bb6ad8cab01b7bbbebe6d1065317")
	, ("HmacSha384", HmacSha384, "3d10d391bee2364df2c55cf605759373e1b5a4ca9355d8f3fe42970471eca2e422a79271a0e857a69923839015877fc6")
	, ("HmacSha512", HmacSha512, "114682914c5d017dfe59fdc804118b56a3a652a0b8870759cf9e792ed7426b08197076bf7d01640b1b0684df79e4b67e37485669e8ce98dbab60445f0db94fce")
	]
  where
	key = T.encodeUtf8 $ T.pack "foo"
	msg = T.encodeUtf8 $ T.pack "bar"
