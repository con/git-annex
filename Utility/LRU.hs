{- LRU
 -
 - Copyright 2026 Joey Hess <id@joeyh.name>
 -
 - License: BSD-2-clause
 -}

module Utility.LRU (
	LRU,
	emptyLRU,
	listLRU,
	addLRU,
	removeLRU,
	popLRU,
	mapLRU,
	testLRU,
	prop_LRU_sane,
) where

import qualified Data.Map as M

data LRU k v = LRU
	{ lruFirst :: Maybe k
	, lruLast :: Maybe k
	, lruMap :: M.Map k (LinkedVal k v)
	}
	deriving (Show, Eq)

data LinkedVal k v = LinkedVal
	{ value :: v
	, prev :: Maybe k
	, next :: Maybe k
	}
	deriving (Show, Eq)

setvalue :: Ord k => v -> k -> M.Map k (LinkedVal k v) -> M.Map k (LinkedVal k v)
setvalue v = M.adjust (\linkedval -> linkedval { value = v })

setprev :: Ord k => Maybe k -> k -> M.Map k (LinkedVal k v) -> M.Map k (LinkedVal k v)
setprev v = M.adjust (\linkedval -> linkedval { prev = v })

setnext :: Ord k => Maybe k -> k -> M.Map k (LinkedVal k v) -> M.Map k (LinkedVal k v)
setnext v = M.adjust (\linkedval -> linkedval { next = v })

emptyLRU :: LRU k v
emptyLRU = LRU Nothing Nothing M.empty

listLRU :: Ord k => LRU k v -> [(k, v)]
listLRU lru = case lruFirst lru of
	Nothing -> []
	Just k -> walk k
  where
	walk k = case M.lookup k (lruMap lru) of
		Nothing -> []
		Just linkedval -> (k, value linkedval) :
			case prev linkedval of
				Just k' -> walk k'
				Nothing -> []

removeLRU :: Ord k => LRU k v -> k -> LRU k v
removeLRU lru k = case M.lookup k (lruMap lru) of
	Nothing -> lru
	Just linkedval -> 
		let lru' = addLRU lru k (value linkedval)
		in lru'
			{ lruLast = case lruLast lru' of
				Nothing -> Nothing
				Just k' -> case M.lookup k' (lruMap lru') of
					Nothing -> Nothing
					Just linkedval' -> next linkedval'
			, lruMap = M.delete k $ unsetprev $ lruMap lru'
			}
  where
	unsetprev m = case M.lookup k m of
		Nothing -> m
		Just linkedval -> case next linkedval of
			Nothing -> m
			Just k' -> setprev Nothing k' m

{- When the key already exists in the LRU, its value is updated, and it is
 - made the most recently added. -}
addLRU :: Ord k => LRU k v -> k -> v -> LRU k v
addLRU lru k v
	| lruLast lru == Just k = lru
		{ lruMap = setvalue v k (lruMap lru)
		}
	| otherwise = LRU
		{ lruFirst = newfirst
		, lruLast = Just k
		, lruMap = 
			let linkedval = LinkedVal
				{ value = v
				, prev = Nothing
				, next = lruLast lru
				}
			in updatefirst $ M.insert k linkedval $
				skipover $ updateprev $ lruMap lru
		}
  where
	newfirst = case lruFirst lru of
		Nothing -> Just k
		Just k'
			| k' /= k -> Just k'
			| otherwise -> case M.lookup k' (lruMap lru) of
				Nothing -> Nothing
				Just linkedval -> prev linkedval
	updateprev m = case lruLast lru of
		Nothing -> m
		Just k' -> setprev (Just k) k' m
	updatefirst m = case newfirst of
		Nothing -> m
		Just k' -> setnext Nothing k' m
	skipover m = case M.lookup k m of
		Nothing -> m
		Just linkedval -> case (prev linkedval, next linkedval) of
			(Just prevk, Just nextk) -> 
				setprev (Just prevk) nextk $
					setnext (Just nextk) prevk m
			_  -> m

popLRU :: Ord k => LRU k v -> (LRU k v, Maybe (k, v))
popLRU lru = case lruFirst lru of
	Nothing -> (lru, Nothing)
	Just first ->
		case M.lookup first (lruMap lru) of
			Nothing -> (lru, Nothing)
			Just linkedval ->
				let lru' = LRU
					{ lruFirst = prev linkedval
					, lruLast = case lruLast lru of
						Just k | k == first -> Nothing
						_ -> lruLast lru
					, lruMap = skipover linkedval $
						M.delete first (lruMap lru)
					}
				in (lru', Just (first, value linkedval))
  where
	skipover linkedval m = case prev linkedval of
		Just k -> setnext Nothing k m
		Nothing -> m

mapLRU :: (Ord k, Ord k') => (k -> k') -> (v -> v') -> LRU k v -> LRU k' v'
mapLRU kf vf lru = LRU
	{ lruFirst = kf <$> lruFirst lru
	, lruLast = kf <$> lruLast lru
	, lruMap = M.fromList $ map go $ M.toList $ lruMap lru
	}
  where
	go (k, linkedval) = 
		(kf k, linkedval
			{ value = vf (value linkedval)
			, prev = kf <$> prev linkedval
			, next = kf <$> next linkedval
			})

prop_LRU_sane :: Bool
prop_LRU_sane = and testLRU

testLRU :: [Bool]
testLRU =
	[ listLRU (fst (popLRU l1)) == []
	, listLRU l1 == [(1, foo)]
	, listLRU l2 == [(1, foo), (2, bar)]
	, listLRU l3 == [(1, foo),(2, bar),(3, baz)]
	, listLRU l4 == [(1, foo),(2, bar),(3, baz), (4, new)]
	, popLRU l1 == (emptyLRU, Just (1, foo))
	, popLRU l2 == (l2no1, Just (1, foo))
	, popLRU l3 == (l3no1, Just (1, foo))
	, popLRU (fst (popLRU l1)) == (emptyLRU, Nothing)
	, popLRU (fst (popLRU (fst (popLRU l2)))) == (emptyLRU, Nothing)
	, addLRU l3 1 new == addLRU l3no1 1 new
	, addLRU l3 2 new == addLRU (addLRU l1 3 baz) 2 new
	, addLRU l3 3 new == addLRU l2 3 new
	, removeLRU emptyLRU 1 == (emptyLRU :: LRU Int String)
	, removeLRU l2 3 == l2
	, removeLRU l3 3 == l2
	, removeLRU l3 1 == l3no1
	, removeLRU l3 2 == addLRU l1 3 baz
	, removeLRU l2 2 == l1
	, removeLRU l2 1 == l2no1
	, removeLRU l4 4 == l3
	, removeLRU l4 2 == addLRU (addLRU l1 3 baz) 4 new
	, removeLRU l4 3 == addLRU l2 4 new
	, removeLRU l4 1 == addLRU l3no1 4 new
	]
  where
	l1 = addLRU emptyLRU (1 :: Int) foo
	l2 = addLRU l1 2 bar
	l3 = addLRU l2 3 baz
	l4 = addLRU l3 4 new
	l2no1 = addLRU emptyLRU 2 bar
	l3no1 = addLRU l2no1 3 baz
	foo = "foo"
	bar = "bar"
	baz = "baz"
	new = "new"
