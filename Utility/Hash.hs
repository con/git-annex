{- Convenience wrapper for hashing libraries.
 -
 - Copyright 2026 Joey Hess <id@joeyh.name>
 -
 - License: BSD-2-clause
 -}

{-# LANGUAGE OverloadedStrings, CPP #-}

module Utility.Hash (module X, props_hashes_stable) where

import Utility.Hash.Types as X
import Utility.Hash.Incremental as X
import Utility.Hash.Botan as X
-- Fall back to crypton for hashes not in botan.
import Utility.Hash.Crypton as X
	( skein256
	, skein256_hasher
	, blake2s_160
	, blake2s_160_hasher
	, blake2s_224
	, blake2s_224_hasher
	, blake2s_256
	, blake2s_256_hasher
	, blake2sp_224
	, blake2sp_224_hasher
	, blake2sp_256
	, blake2sp_256_hasher
	, blake2bp_512
	, blake2bp_512_hasher
	)
#ifdef WITH_BLAKE3
import Utility.Hash.Blake3 as X
#endif
#ifdef WITH_XXH3
import Utility.Hash.XXH3 as X
#endif

import qualified Data.ByteString.Lazy as L
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

{- Check that all the hashes continue to hash the same. -}
props_hashes_stable :: [(String, Bool)]
props_hashes_stable = map testhash $
	[ ("sha1", digestToHash . sha1, "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33")
	, ("sha2_224", digestToHash . sha2_224, "0808f64e60d58979fcb676c96ec938270dea42445aeefcd3a4e6f8db")
	, ("sha2_256", digestToHash . sha2_256, "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae")
	, ("sha2_384", digestToHash . sha2_384, "98c11ffdfdd540676b1a137cb1a22b2a70350c9a44171d6b1180c6be5cbb2ee3f79d532c8a1dd9ef2e8e08e752a3babb")
	, ("sha2_512", digestToHash . sha2_512, "f7fbba6e0636f890e56fbbf3283e524c6fa3204ae298382d624741d0dc6638326e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7")
	, ("skein256", digestToHash . skein256, "a04efd9a0aeed6ede40fe5ce0d9361ae7b7d88b524aa19917b9315f1ecf00d33")
	, ("skein512", digestToHash . skein512, "fd8956898113510180aa4658e6c0ac85bd74fb47f4a4ba264a6b705d7a8e8526756e75aecda12cff4f1aca1a4c2830fbf57f458012a66b2b15a3dd7d251690a7")
	, ("sha3_224", digestToHash . sha3_224, "f4f6779e153c391bbd29c95e72b0708e39d9166c7cea51d1f10ef58a")
	, ("sha3_256", digestToHash . sha3_256, "76d3bc41c9f588f7fcd0d5bf4718f8f84b1c41b20882703100b9eb9413807c01")
	, ("sha3_384", digestToHash . sha3_384, "665551928d13b7d84ee02734502b018d896a0fb87eed5adb4c87ba91bbd6489410e11b0fbcc06ed7d0ebad559e5d3bb5")
	, ("sha3_512", digestToHash . sha3_512, "4bca2b137edc580fe50a88983ef860ebaca36c857b1f492839d6d7392452a63c82cbebc68e3b70a2a1480b4bb5d437a7cba6ecf9d89f9ff3ccd14cd6146ea7e7")
	, ("blake2s_160", digestToHash . blake2s_160, "52fb63154f958a5c56864597273ea759e52c6f00")
	, ("blake2s_224", digestToHash . blake2s_224, "9466668503ac415d87b8e1dfd7f348ab273ac1d5e4f774fced5fdb55")
	, ("blake2s_256", digestToHash . blake2s_256, "08d6cad88075de8f192db097573d0e829411cd91eb6ec65e8fc16c017edfdb74")
	, ("blake2sp_224", digestToHash . blake2sp_224, "8492d356fbac99f046f55e114301f7596649cb590e5b083d1a19dcdb")
	, ("blake2sp_256", digestToHash . blake2sp_256, "050dc5786037ea72cb9ed9d0324afcab03c97ec02e8c47368fc5dfb4cf49d8c9")
	, ("blake2b_160", digestToHash . blake2b_160, "983ceba2afea8694cc933336b27b907f90c53a88")
	, ("blake2b_224", digestToHash . blake2b_224, "853986b3fe231d795261b4fb530e1a9188db41e460ec4ca59aafef78")
	, ("blake2b_256", digestToHash . blake2b_256, "b8fe9f7f6255a6fa08f668ab632a8d081ad87983c77cd274e48ce450f0b349fd")
	, ("blake2b_384", digestToHash . blake2b_384, "e629ee880953d32c8877e479e3b4cb0a4c9d5805e2b34c675b5a5863c4ad7d64bb2a9b8257fac9d82d289b3d39eb9cc2")
	, ("blake2b_512", digestToHash . blake2b_512, "ca002330e69d3e6b84a46a56a6533fd79d51d97a3bb7cad6c2ff43b354185d6dc1e723fb3db4ae0737e120378424c714bb982d9dc5bbd7a0ab318240ddd18f8d")
	, ("blake2bp_512", digestToHash . blake2bp_512, "8ca9ccee7946afcb686fe7556628b5ba1bf9a691da37ca58cd049354d99f37042c007427e5f219b9ab5063707ec6823872dee413ee014b4d02f2ebb6abb5f643")
	, ("md5", digestToHash . md5, "acbd18db4cc2f85cedef654fccc4a4d8")
	]
#ifdef WITH_BLAKE3
	++ [("blake3", blake3, "04e0bb39f30b1a3feb89f536c93be15055482df748674b00d26e5a75777702e9")]
#endif
#ifdef WITH_XXH3
	++ if xxh3Supported
		then [("xxh3", digestToHash . xxh3, "ab6e5f64077e7d8a")]
		else []
#endif
  where
	testhash (desc, hasher, result) = 
		(desc ++ " stable", hasher foo == result)
	foo = L.fromChunks [T.encodeUtf8 $ T.pack "foo"]
