{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, FlexibleContexts #-}
module Data.Ring.Semi.Near.Trie 
    ( module Data.Ring
    , Trie(Trie, total, label, children)
    , singleton
    , empty
    , null
    ) where
    
import Data.Map (Map)
import qualified Data.Map as Map
import Data.Monoid.Union hiding (empty)
import Data.Ring
import Prelude hiding (null)

singleton :: (Ord c, c `Reducer` m) => c -> Trie c m 
singleton = unit

empty :: (Ord c, Monoid m) => Trie c m
empty = zero

null :: Ord c => Trie c m -> Bool
null = Map.null . getUnionWith . children

data Trie c m = Trie { total :: m, label :: m, children :: UnionWith (Map c) (Trie c m) }
    deriving (Eq,Show)

instance Functor (Trie c) where
    fmap f (Trie t e r) = Trie (f t) (f e) (fmap (fmap f) r)

instance (Ord c, Monoid m) => Monoid (Trie c m) where
    mempty = Trie mempty mempty mempty
    Trie x y z `mappend` Trie x' y' z' = Trie (x `mappend` x') (y `mappend` y') (z `mappend` z')

instance (Ord c, c `Reducer` m) => Reducer c (Trie c m) where
    unit c = Trie r zero . UnionWith $ flip Map.singleton (Trie r r zero) c where r = unit c

{-
instance (Ord c, Eq r, RightSemiNearRing r) => Multiplicative (Trie c r) where
    one = Trie one one zero
    Trie t e r `times` rhs@(Trie t' e' r') = 
        Trie (t `times` t') (e `times` e') (r .* rhs `plus` lhs *. r') where
            lhs = Trie e e zero `asTypeOf` rhs

instance (Ord c, Eq r, RightSemiNearRing r) => RightSemiNearRing (Trie c r)

toList :: (Ord c, c `Reducer` [c]) => Trie c m -> [[c]]
toList = fmap merge . Map.assocs . getUnionWith . children where
    merge (k,t) = k `times` toList t
-}
