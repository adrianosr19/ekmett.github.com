{-# OPTIONS_GHC -fglasgow-exts #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Functor.Extras
-- Copyright   :  (C) 2008 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable (rank-2 polymorphism)
--
----------------------------------------------------------------------------
module Control.Functor.Extras where

infixr 0 :~>, :~~> -- to match ->

type Dist f g = forall a. f (g a) -> g (f a)

-- A natural transformation between functors f and g.
type f :~> g = forall a. f a -> g a

-- Its bifunctorial analogue
type f :~~> g = forall a b. f a b -> g a b

-- Dinatural transformations
type Dinatural f g = forall a. f a a -> g a a

class PostFold m f where
        postFold :: f (m (f a)) -> m (f a)

class PostUnfold w f where
        postUnfold :: w (f a) -> f (w (f a))

class PreFold f m where
        preFold :: f (m (f a)) -> f (m a)

class PreUnfold f w where
        preUnfold :: f (w a) -> f (w (f a))

class Distributes f g where
        dist :: f (g a) -> g (f a)



class Functor f => FunctorZero f where
	fzero :: f a

-- monoid
class FunctorZero f => FunctorPlus f where
	fplus :: f a -> f a -> f a

class Functor f => FunctorSplit f where
	fsplit :: f a -> (f a, f a)
