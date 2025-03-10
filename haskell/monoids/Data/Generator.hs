{-# LANGUAGE UndecidableInstances, TypeOperators, FlexibleContexts, MultiParamTypeClasses, FlexibleInstances, TypeFamilies, CPP #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Generator
-- Copyright   :  (c) Edward Kmett 2009
-- License     :  BSD-style
-- Maintainer  :  ekmett@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-- A 'Generator' @c@ is a possibly-specialized container, which contains values of 
-- type 'Elem' @c@, and which knows how to efficiently apply a 'Reducer' to extract
-- an answer.
--
-- Since a 'Generator' is not polymorphic in its contents, it is more specialized
-- than "Data.Foldable.Foldable", and a 'Reducer' may supply efficient left-to-right
-- and right-to-left reduction strategies that a 'Generator' may avail itself of.
-----------------------------------------------------------------------------

module Data.Generator
    ( module Data.Monoid.Reducer
    -- * Generators
    , Generator
    , Elem
    , mapReduce
    , mapTo
    , mapFrom
    -- * Generator Transformers
    , Keys(Keys, getKeys)
    , Values(Values, getValues)
    , Char8(Char8, getChar8)
    -- * Combinators
    , reduce
    , mapReduceWith
    , reduceWith
    ) where

#ifdef M_ARRAY
import Data.Array 
#endif


#ifdef M_TEXT
import Data.Text (Text)
import qualified Data.Text as Text
#endif


#ifdef M_BYTESTRING
import qualified Data.ByteString as Strict (ByteString, foldl')
import qualified Data.ByteString.Char8 as Strict8 (foldl')
import qualified Data.ByteString.Lazy as Lazy (ByteString, toChunks)
import qualified Data.ByteString.Lazy.Char8 as Lazy8 (toChunks)
import Data.Word (Word8)
#endif

#ifdef M_FINGERTREE
import Data.FingerTree (Measured, FingerTree)
#endif

#ifdef M_CONTAINERS
import qualified Data.Sequence as Seq
import Data.Sequence (Seq)
import qualified Data.Set as Set
import Data.Set (Set)
import qualified Data.IntSet as IntSet
import Data.IntSet (IntSet)
import qualified Data.IntMap as IntMap
import Data.IntMap (IntMap)
import qualified Data.Map as Map
import Data.Map (Map)
#endif

#ifdef M_PARALLEL
import Control.Parallel.Strategies
#endif

import Data.Foldable (fold,foldMap)
import Data.Monoid.Reducer

-- | minimal definition 'mapReduce' or 'mapTo'
class Generator c where
    type Elem c :: * 
    mapReduce :: (e `Reducer` m) => (Elem c -> e) -> c -> m
    mapTo     :: (e `Reducer` m) => (Elem c -> e) -> m -> c -> m 
    mapFrom   :: (e `Reducer` m) => (Elem c -> e) -> c -> m -> m

    mapReduce f = mapTo f mempty
    mapTo f m = mappend m . mapReduce f
    mapFrom f = mappend . mapReduce f

#ifdef M_BYTESTRING
instance Generator Strict.ByteString where
    type Elem Strict.ByteString = Word8
    mapTo f = Strict.foldl' (\a -> snoc a . f)

instance Generator Lazy.ByteString where
    type Elem Lazy.ByteString = Word8
    mapReduce f = fold . parMap rwhnf (mapReduce f) . Lazy.toChunks
#endif

#ifdef M_TEXT
instance Generator Text where
    type Elem Text = Char
    mapTo f = Text.foldl' (\a -> snoc a . f)
#endif

instance Generator [c] where
    type Elem [c] = c
    mapReduce f = foldr (cons . f) mempty

#ifdef M_FINGERTREE
instance Measured v e => Generator (FingerTree v e) where
    type Elem (FingerTree v e) = e
    mapReduce f = foldMap (unit . f)
#endif

#ifdef M_CONTAINERS
instance Generator (Seq c) where
    type Elem (Seq c) = c
    mapReduce f = foldMap (unit . f)

instance Generator IntSet where
    type Elem IntSet = Int
    mapReduce f = mapReduce f . IntSet.toList

instance Generator (Set a) where
    type Elem (Set a) = a
    mapReduce f = mapReduce f . Set.toList

instance Generator (IntMap v) where
    type Elem (IntMap v) = (Int,v)
    mapReduce f = mapReduce f . IntMap.toList

instance Generator (Map k v) where
    type Elem (Map k v) = (k,v) 
    mapReduce f = mapReduce f . Map.toList
#endif

#ifdef M_ARRAY
instance Ix i => Generator (Array i e) where
    type Elem (Array i e) = (i,e)
    mapReduce f = mapReduce f . assocs
#endif

-- | a 'Generator' transformer that asks only for the keys of an indexed container
newtype Keys c = Keys { getKeys :: c } 

#ifdef M_CONTAINERS
instance Generator (Keys (IntMap v)) where
    type Elem (Keys (IntMap v)) = Int
    mapReduce f = mapReduce f . IntMap.keys . getKeys

instance Generator (Keys (Map k v)) where
    type Elem (Keys (Map k v)) = k
    mapReduce f = mapReduce f . Map.keys . getKeys
#endif

#ifdef M_ARRAY
instance Ix i => Generator (Keys (Array i e)) where
    type Elem (Keys (Array i e)) = i
    mapReduce f = mapReduce f . range . bounds . getKeys
#endif

-- | a 'Generator' transformer that asks only for the values contained in an indexed container
newtype Values c = Values { getValues :: c } 

#ifdef M_CONTAINERS
instance Generator (Values (IntMap v)) where
    type Elem (Values (IntMap v)) = v
    mapReduce f = mapReduce f . IntMap.elems . getValues

instance Generator (Values (Map k v)) where
    type Elem (Values (Map k v)) = v
    mapReduce f = mapReduce f . Map.elems . getValues
#endif

#ifdef M_ARRAY
instance Ix i => Generator (Values (Array i e)) where
    type Elem (Values (Array i e)) = e
    mapReduce f = mapReduce f . elems . getValues
#endif

-- | a 'Generator' transformer that treats 'Word8' as 'Char'
-- This lets you use a 'ByteString' as a 'Char' source without going through a 'Monoid' transformer like 'UTF8'
newtype Char8 c = Char8 { getChar8 :: c } 

#ifdef M_BYTESTRING
instance Generator (Char8 Strict.ByteString) where
    type Elem (Char8 Strict.ByteString) = Char
    mapTo f m = Strict8.foldl' (\a -> snoc a . f) m . getChar8

instance Generator (Char8 Lazy.ByteString) where
    type Elem (Char8 Lazy.ByteString) = Char
    mapReduce f = fold . parMap rwhnf (mapReduce f . Char8) . Lazy8.toChunks . getChar8
#endif

-- | Apply a 'Reducer' directly to the elements of a 'Generator'
reduce :: (Generator c, Elem c `Reducer` m) => c -> m
reduce = mapReduce id
#ifdef M_BYTESTRING
{-# SPECIALIZE reduce :: (Word8 `Reducer` m) => Strict.ByteString -> m #-}
{-# SPECIALIZE reduce :: (Word8 `Reducer` m) => Lazy.ByteString -> m #-}
{-# SPECIALIZE reduce :: (Char `Reducer` m) => Char8 Strict.ByteString -> m #-}
{-# SPECIALIZE reduce :: (Char `Reducer` m) => Char8 Lazy.ByteString -> m #-}
#endif
{-# SPECIALIZE reduce :: (c `Reducer` m) => [c] -> m #-}
#ifdef M_FINGERTREE
{-# SPECIALIZE reduce :: (Generator (FingerTree v e), e `Reducer` m) => FingerTree v e -> m #-}
#endif
#ifdef M_TEXT
{-# SPECIALIZE reduce :: (Char `Reducer` m) => Text -> m #-}
#endif
#ifdef M_CONTAINERS
{-# SPECIALIZE reduce :: (e `Reducer` m) => Seq e -> m #-}
{-# SPECIALIZE reduce :: (Int `Reducer` m) => IntSet -> m #-}
{-# SPECIALIZE reduce :: (a `Reducer` m) => Set a -> m #-}
{-# SPECIALIZE reduce :: ((Int,v) `Reducer` m) => IntMap v -> m #-}
{-# SPECIALIZE reduce :: ((k,v) `Reducer` m) => Map k v -> m #-}
{-# SPECIALIZE reduce :: (Int `Reducer` m) => Keys (IntMap v) -> m #-}
{-# SPECIALIZE reduce :: (k `Reducer` m) => Keys (Map k v) -> m #-}
{-# SPECIALIZE reduce :: (v `Reducer` m) => Values (IntMap v) -> m #-}
{-# SPECIALIZE reduce :: (v `Reducer` m) => Values (Map k v) -> m #-}
#endif

mapReduceWith :: (Generator c, e `Reducer` m) => (m -> n) -> (Elem c -> e) -> c -> n
mapReduceWith f g = f . mapReduce g
{-# INLINE mapReduceWith #-}

reduceWith :: (Generator c, Elem c `Reducer` m) => (m -> n) -> c -> n
reduceWith f = f . reduce
{-# INLINE reduceWith #-}
