{-# LANGUAGE TypeOperators, Rank2Types, EmptyDataDecls, 
             MultiParamTypeClasses, FunctionalDependencies, 
             FlexibleContexts, FlexibleInstances, UndecidableInstances,
             TypeFamilies, IncoherentInstances, OverlappingInstances #-}
module Data.Rope.Annotated
    ( -- * Annotated 'Rope's 
      A(rope)   
    , Ann
    , MonoidA, ReducerA, BreakableA 
    , runAnn     -- :: Ann a f -> (forall b. Ann b f -> r) -> r

      -- * Unpacking 'Ropes'
    , null      -- :: A s a -> Bool
    , head      -- :: Unpackable t => A s a -> t
    , last      -- :: Unpackable t => A s a -> t
    , unpack    -- :: Unpackable t => A s a -> [t]

      -- * Building Annotated 'Rope'
    , empty     -- :: MonoidA f => Ann Empty f 
    , append    -- :: MonoidA f => Ann a f -> Ann b f -> Ann (a :<> b) f

    , unit      -- :: (ReducerA f, Reducer t Rope) => t -> (forall a. Ann (Return a) f -> r) -> r
    , snoc      -- :: (ReducerA f, Reducer t Rope) => t -> Ann a f -> (forall c. Ann (Snoc c t a) f -> r) -> r
    , cons      -- :: (ReducerA f, Reducer t Rope) => Ann a f -> t -> (forall c. Ann (Cons c t a) f -> r) -> r

      -- * Cutting An Annotated 'Rope'
    , splitAt   -- :: (BreakablaA f) => Int -> Ann a f -> (forall n. Ann (Take n a) f -> Ann (Drop n a) f -> r) -> r
    , drop      -- :: (BreakableA f) => Int -> Ann a f -> (forall n. Ann (Drop n a) f -> r) -> r
    , take      -- :: (BreakablaA f) => Int -> Ann a f -> (forall n. Ann (Take n a) f -> r) -> r

    , break     -- :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> Ann (Drop n a) f -> r) -> r
    , span      -- :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> Ann (Drop n a) f -> r) -> r
    , takeWhile -- :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> r) -> r
    , dropWhile -- :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Drop n a) f -> r) -> r

    -- * Inspecting the ends of the 'Rope'
    , uncons    -- :: (BreakableA f, Unpackable t) => Ann a f -> Maybe (t, Ann (Tail t b) f)
    , unsnoc    -- :: (BreakableA f, Unpackable t) => Ann a f -> Maybe (Ann (Init b t) f, t)

    -- * Type-level constructors
    , Drop, Take, Snoc, Cons, Tail, Init, Return, Nil , (:<>)
    , Tailed, Inited, Dropped, Taken, Nil, (:>)

    -- * Annotations
    -- ** Annotation Product
    , (:*:)(..)
    , fstF      -- :: (f :*: g) a -> f a 
    , sndF      -- :: (f :*: g) a -> g a
    -- ** Annotation Unit
    , Unit
    ) where

import Prelude hiding (null, head, last, take, drop, span, break, splitAt, takeWhile, dropWhile)
import Data.Monoid

import qualified Data.Rope.Internal as Rope

import Data.Rope.Annotated.Internal (A(..), null, head, last, unpack)
import Data.Rope.Annotation
import Data.Rope.Annotation.Product
import Data.Rope.Annotation.Unit

import Data.Rope.Util.Reducer (Reducer)
import qualified Data.Rope.Util.Reducer as Reducer

import Data.Rope.Internal (Rope(..),Breakable, Unpackable)

type Ann a f = A a (f a)

data Nil
data a :> b 

type family a :<> b :: *
type instance (a :> b) :<> c = a :> (b :<> c)
type instance Nil :<> c = c 
type Return a = a :> Nil

data Taken n a
type family Take n a :: *
type instance Take n Nil = Nil
type instance Take n (a :> b) = Return (Taken n (a :> b))

data Dropped n a 
type family Drop n a :: *
type instance Drop n Nil = Nil
type instance Drop n (a :> b) = Return (Dropped n (a :> b))

data Token s t 
type Cons s t a = Token s t :> a
type Snoc a s t = a :<> Return (Token s t)

data Tailed t a 
type Tail t a = Return (Tailed t a)

data Inited a t
type Init a t = Return (Inited a t)

runAnn :: Ann a f -> (forall b. Ann b f -> r) -> r
runAnn a k = k a 

empty :: MonoidA f => Ann Nil f
empty = A Rope.empty emptyA

append :: MonoidA f => Ann a f -> Ann b f -> Ann (a :<> b) f
append (A r a) (A s b) = A (r `mappend` s) (appendA r a s b)

unit :: (ReducerA f, Reducer t Rope) => t -> (forall a. Ann (Return a) f -> r) -> r
unit t k = k (A r (unitA r)) 
    where 
        r :: Rope
        r = Reducer.unit t

splitAt :: BreakableA f => Int -> Ann a f -> (forall n. Ann (Take n a)  f -> Ann (Drop n a) f -> r) -> r
splitAt n (A r a) k = k (A r b) (A r c) 
    where (b, c) = splitAtA n r a

drop :: BreakableA f => Int -> Ann a f -> (forall n. Ann (Drop n a) f -> r) -> r
drop n (A r a) k = k (A r (dropA n r a))

take :: BreakableA f => Int -> Ann a f -> (forall n. Ann (Take n a) f -> r) -> r
take n (A r a) k = k (A r (takeA n r a))

snoc :: (ReducerA f, Reducer t Rope) => Ann a f -> t -> (forall c. Ann (Snoc a c t) f -> r) -> r
snoc (A r a) t k = k (A r' (snocA (Rope.length r' - Rope.length r) r' a))
    where r' = Reducer.snoc r t 

cons :: (ReducerA f, Reducer t Rope) => t -> Ann a f -> (forall c. Ann (Cons c t a) f -> r) -> r
cons t (A r a) k = k (A r' (consA (Rope.length r' - Rope.length r) r' a))
    where r' = Reducer.cons t r

break :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> Ann (Drop n a) f -> r) -> r
break p (A r a) k = k (A x b) (A y c) where
    (x,y) = Rope.break p r
    (b,c) = splitAtA (Rope.length x) r a

span :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> Ann (Drop n a) f -> r) -> r
span p (A r a) k = k (A x b) (A y c) where
    (x,y) = Rope.span p r
    (b,c) = splitAtA (Rope.length x) r a

takeWhile :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Take n a) f -> r) -> r
takeWhile p (A r a) k = k (A x b) where
    x = Rope.takeWhile p r
    b = takeA (Rope.length x) r a

dropWhile :: (BreakableA f, Breakable t) => (t -> Bool) -> Ann a f -> (forall n. Ann (Drop n a) f -> r) -> r
dropWhile p (A r a) k = k (A y c) where
    y = Rope.dropWhile p r
    c = dropA (Rope.length r - Rope.length y) r a

uncons :: (BreakableA f, Unpackable t) => Ann a f -> Maybe (t, Ann (Tail t a) f)
uncons (A r a) = case Rope.uncons r of
    Just (c,cs) -> Just (c, A cs (dropA (Rope.length r - Rope.length cs) r a))
    Nothing -> Nothing

unsnoc :: (BreakableA f, Unpackable t) => Ann a f -> Maybe (Ann (Init a t) f, t)
unsnoc (A r a) = case Rope.unsnoc r of
    Just (cs,c) -> Just (A cs (dropA (Rope.length cs) r a), c)
    Nothing -> Nothing

