{-# LANGUAGE TypeOperators #-}
module Data.Rope.Util.Coproduct
    ( (:+:)(..)
    , (:+)(..)
    , Coproduct(..)
    , counzip
    ) where

import Control.Applicative
import Data.Rope.Util.Bifunctor

counzip :: (Coproduct s, Coproduct s', Functor f) => s (f a) (f b) -> f (s' a b)
counzip = fmap left ||| fmap right

-- a coproduct that is strict in its left argument only
data a :+ b = Inl !a
            | Inr b

instance Bifunctor (:+) where
    first f (Inl a) = Inl (f a)
    first _ (Inr b) = Inr b
    second _ (Inl a) = Inl a
    second g (Inr b) = Inr (g b)
    bimap f _ (Inl a) = Inl (f a)
    bimap _ g (Inr b) = Inr (g b)

instance Functor ((:+) a) where
    fmap _ (Inl a) = Inl a
    fmap g (Inr b) = Inr (g b)

instance Applicative ((:+)  a) where
    pure = Inr
    Inl a <*> _ = Inl a
    Inr _ <*> Inl a = Inl a
    Inr f <*> Inr a = Inr (f a)
    
instance Monad ((:+) a) where
    return = Inr
    Inl a >>= _ = Inl a
    Inr a >>= f = f a

class Bifunctor s => Coproduct s where
    left :: a -> s a b
    right :: b -> s a b
    (|||) :: (a -> c) -> (b -> c) -> s a b -> c
    codiag :: s a a -> a

instance Coproduct Either where
    left = Left
    right = Right
    (|||) = either
    codiag (Left a) = a
    codiag (Right a) = a

instance Coproduct (:+) where
    left = Inl
    right = Inr
    (|||) f _ (Inl a) = f a
    (|||) _ g (Inr b) = g b
    codiag (Inl a) = a 
    codiag (Inr a) = a

data a :+: b = Left' !a 
             | Right' !b

instance Bifunctor (:+:) where
    first f (Left' a) = Left' (f a)
    first _ (Right' b) = Right' b
    second _ (Left' a) = Left' a
    second g (Right' b) = Right' (g b)
    bimap f _ (Left' a) = Left' (f a)
    bimap _ g (Right' b) = Right' (g b)

instance Functor ((:+:) a) where
    fmap _ (Left' a) = Left' a
    fmap g (Right' b) = Right' (g b)

instance Coproduct (:+:) where
    left = Left'
    right = Right'
    (|||) f _ (Left' a) = f a
    (|||) _ g (Right' b) = g b
    codiag (Left' a) = a
    codiag (Right' a) = a
