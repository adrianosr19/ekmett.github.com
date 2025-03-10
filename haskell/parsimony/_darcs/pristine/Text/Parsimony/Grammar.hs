{-# LANGUAGE KindSignatures, TypeFamilies, GADTs, EmptyDataDecls, FlexibleContexts, FlexibleInstances, Rank2Types #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Text.Parsimony.Grammar
-- Copyright   :  (c) Edward Kmett 2009
-- License     :  BSD
-- Maintainer  :  ekmett@gmail.com
-- Stability   :  experimental
-- Portability :  non-portable (type families, GADTs)
--
-- Parallel parser combinators
--
-----------------------------------------------------------------------------

module Text.Parsimony.Grammar
    where

import Control.Applicative
import Control.Arrow (Arrow, arr)
import Control.Category
import Prelude hiding ((.),id)
import Text.Parsimony.StableMap
import Text.Parsimony.Util
import Data.Traversable
import Unsafe.Coerce (unsafeCoerce)
import Control.Monad.State.Class
import Control.Monad.Trans

type State = Int

data Leaf m t r = forall b. Leaf {-# UNPACK #-} !Int (Fun m t b) (t -> Bool) (Path (Parser m t) (Const Int) r b)

-- a bottom-up zipper of an applicative
data Path f p r b where
    Top :: Path f p r r 
    Car :: f a -> p r b -> Path f p r (a -> b) 
    Cdr :: f (a -> b) -> p r b -> Path f p r a
    Amb :: [Path f p r a] -> Path f p r a

data CofreePath f r a = CofreePath (a, Path f (CofreePath f r a) r b)
    
data Zipper f r = Zipper { getPath :: Path f (Path f) r

amb :: Path m t r b -> Path m t r b -> Path m t r b
amb (Amb as) (Amb bs) = Amb (as ++ bs)
amb (Amb as) b        = Amb (as ++ [b])
amb a        (Amb bs) = Amb (a:bs)
amb a        b        = Amb [a,b]

rec = amb

data Meta r p where
    Meta :: {-# UNPACK #-} !Int -> Bool -> f a -> Path m t r a -> Meta r (f a)

id (Meta i _ _ _)     = i
status (Meta _ b _ _) = b
parser (Meta _ _ p _) = p
path (Meta _ _ _ p)   = p

share :: Mode m => Int -> Path m t root a -> Parser m t a -> S root [Leaf m t root]
share !pid path parser = do
    name <- liftIO $ makeStableName parser
    m <- get
    case StableMap.lookup name m of 
        Nothing -> do
            id <- fresh
            modify $ \m -> StableMap.insert m (Meta id parser path) }
            leaves <- case p of
                Satisfy f p -> return [Leaf id f path]
                App f x -> do
                    as <- share id (Car x path) f 
                    bs <- share id (Cdr f path) x
                    return (as ++ bs)
                Alt parsers -> concat <$> mapM (share pid path) parsers
                Name parser' _ -> share pid path parser'
                -- TODO: these two need to be fixed
                Labels parser' labels -> share pid path parser'
                Greedy parsers -> concat <$> mapM (share pid path) parsers
        Just (Meta id open parser' path') 
            --| otherwise -> do
                modify $ StableMap.update name $ \ _ -> Meta id open parser' $ path `amb` path'

-- monad
-- fast StateT IO with fresh variable supply and map
newtype S r a = S { runS :: forall o. (a -> StableMap (Meta r) -> Int# -> o) -> StableMap (Meta r) -> Int# -> IO o } 

instance Functor (S r) where
    fmap f g = S (\k -> runS g (k . f))

instance Monad (S r) where
    return a = S (\k -> k a)
    S g >>= f = S (\k -> g (\a -> runS (f a) k))

fresh :: S r Int
fresh = S (\k s i -> k (I# i) s (i +# 1#))

instance MonadState (StableMap (Meta r)) (S r) where
    get = S (\k s -> k s s)
    put s = S (\k _ -> k () s)

instance MonadIO (S r) where
    liftIO f = S (\k s i -> k (\a _ _ -> a) s i >>= f)

runS :: S r a -> IO (a, StableMap (Meta r), Int)
runS (S k) = k (\a s' i' -> return (a, s', I# i)) StableMap.empty 1#
