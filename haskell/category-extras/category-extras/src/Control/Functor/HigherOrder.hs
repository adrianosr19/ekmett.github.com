{-# OPTIONS_GHC -fglasgow-exts #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Functor.HigherOrder
-- Copyright   :  (C) 2008 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable (rank-2 polymorphism)
--
-- Neil Ghani and Particia Johann''s higher order functors from
-- <http://crab.rutgers.edu/~pjohann/tlca07-rev.pdf>
----------------------------------------------------------------------------
module Control.Functor.HigherOrder 
	( HFunctor(..)
	, HPointed(..)
	, HCopointed(..)
	, HAlgebra
	, HCoalgebra
	, FixH(..)
	, LowerH(..)
	) where

import Control.Functor.Pointed
import Control.Functor.Extras

type HAlgebra f g = f g :~> g
type HCoalgebra f g = g :~> f g

class HFunctor f where
	ffmap :: Functor g => (a -> b) -> f g a -> f g b
	hfmap :: (g :~> h) -> f g :~> f h

newtype FixH f a = InH { outH :: f (FixH f) a }

class HFunctor m => HPointed m where
	hreturn  :: Functor f => f a -> m f a

class HFunctor w => HCopointed w where
	hextract :: Functor f => w f a -> f a

newtype LowerH 
	(h :: (* -> *) -> * -> *)
	(f :: * -> *)
	(a :: *) = LowerH { liftH :: h f a }

instance (HFunctor h, Functor f) => Functor (LowerH h f) where
	fmap f = LowerH . ffmap f . liftH 

instance (HPointed h, Pointed f) => Pointed (LowerH h f) where
	point = LowerH . hreturn . point

instance (HCopointed h, Copointed f) => Copointed (LowerH h f) where
	extract = extract . hextract . liftH

{-# RULES
"hextract/hreturn" hextract . hreturn = id
 #-}
