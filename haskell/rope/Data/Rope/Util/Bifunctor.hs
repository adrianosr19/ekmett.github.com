module Data.Rope.Util.Bifunctor (Bifunctor(..)) where

class Bifunctor f where
    bimap :: (a -> b) -> (c -> d) -> f a c -> f b d
    first :: (a -> b) -> f a c -> f b c
    second :: (b -> c) -> f a b -> f a c
    first f = bimap f id
    second = bimap id
    bimap f g = second g . first f

instance Bifunctor (,) where
    bimap f g ~(a,b) = (f a, g b)
    first f ~(a,b) = (f a, b)
    second g ~(a,b) = (a, g b)
    
instance Bifunctor Either where
    bimap f _ (Left a) = Left (f a)
    bimap _ g (Right b) = Right (g b)
    first f (Left a) = Left (f a)
    first _ (Right b) = Right b
    second _ (Left a) = Left a
    second g (Right b) = Right (g b)
