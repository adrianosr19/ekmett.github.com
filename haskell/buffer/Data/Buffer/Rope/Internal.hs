{-# LANGUAGE CPP, ForeignFunctionInterface #-}
-- We cannot actually specify all the language pragmas, see ghc ticket #
-- If we could, these are what they would be:
{- LANGUAGE DeriveDataTypeable -}
{-# OPTIONS_HADDOCK hide #-}

-- |
-- Module      : Data.Buffer.Rope.Internal
-- License     : BSD-style
-- Maintainer  : ekmett@gmail.com
-- Stability   : experimental
-- Portability : portable
-- 
-- A module containing semi-public 'Rope' internals. This exposes
-- the 'Buffer' representation and low level construction functions.
-- Modules which extend the 'Rope' system will need to use this module
-- while ideally most users will be able to make do with the public interface
-- modules.

module Data.Buffer.Rope.Internal (
        Rope(..)
        empty,      -- :: Rope
        fromBuffer, -- :: Buffer -> Rope
        consBuffer,
        snocBuffer,
        foldrChunks,
        foldlChunks,

        -- * Buffer allocation sizes
        defaultChunkSize, -- :: Int
        smallChunkSize,   -- :: Int
        extraChunkSize,   -- :: Int 
        chunkOverhead     -- :: Int
  ) where

#define STRICT1(f) f a | a `seq` False = undefined
#define STRICT2(f) f a b | a `seq` b `seq` False = undefined
#define STRICT3(f) f a b c | a `seq` b `seq` c `seq` False = undefined
#define STRICT4(f) f a b c d | a `seq` b `seq` c `seq` d `seq` False = undefined
#define STRICT5(f) f a b c d e | a `seq` b `seq` c `seq` d `seq` e `seq` False = undefined
#define STRICT6(g) g a b c d e f | a `seq` b `seq` c `seq` d `seq` e `seq` f `seq` False = undefined

import Data.Buffer.Internal.Classes
import qualified Data.Buffer.Internal as S

import Foreign.Storable (Storable(sizeOf))

#if defined(__GLASGOW_HASKELL__)
import Data.Typeable    (Typeable)
#if __GLASGOW_HASKELL__ >= 610
import Data.Data        (Data)
#else
import Data.Generics    (Data)
#endif
#endif

-- | A space-efficient representation of a Word8 vector, supporting many
-- efficient operations.  A 'Buffer' contains 8-bit characters only.
--
-- Instances of Eq, Ord, Read, Show, Data, Typeable

-- TODO: provide a custom Data instance that abstracts over this as a container of bytes
data Rope = Rope (FingerTree Buffer)
#if defined(__GLASGOW_HASKELL__)
      deriving (Data, Typeable)
#endif

------------------------------------------------------------------------

-- | The data type invariant:
-- Every Buffer is either 'Empty' or consists of non-null 'S.Buffer's.
-- All functions must preserve this, and the QC properties must check this.
-- Furthermore, the number of multibyte tail bytes must be non negative and cannot
-- exceed the total number of bytes

instance Valid Rope where
    valid (Rope t) = valid t

instance Monoid Rope where
    mempty = Rope mempty
    Rope a `mappend` Rope b = Rope (a `mappend` b)

-- | Smart constructor for 'Chunk'. Guarantees the data type invariant.
consBuffer :: Buffer -> Rope -> Rope
consBuffer c (Rope cs) = Rope (singleton c `F.append` cs) 
{-# INLINE consBuffer #-}

-- | Smart constructor for 'Chunk'. Guarantees the data type invariant.
snocBuffer :: Rope -> Buffer -> Rope
snocBuffer (Rope cs) c = Rope (cs `F.append` singleton c)
{-# INLINE snocBuffer #-}

-- | we want to split up a buffer to meet the following ideal conditions before inserting it into a fingertree
-- the empty string results in no output buffers
-- if we only have a small enough chunk left or it contains no extra characters, just emit it. 
-- after that, scan looking for the largest all ascii ([0..7f]) chunk that you can find. If you find more than extraChunkSize
-- bytes in that form, emit it, otherwise, convert what you've seen into an exotic chunk that is exactly your extraChunkSize and start over

-- this ensures that we can insert arbitrarily large chunks that support O(1) indexing, and that the chunks that require
-- O(n) indexing are significantly smaller.`

fromBuffer :: Buffer -> Rope
fromBuffer (PS x s l e) = Rope (foldr F.cons F.empty (run x s l e))
    where big = extraChunkSize

          STRICT4(run)
          run x s l e
            | l < big || e == 0 = 
                if l == 0
                then []
                else [PS x s l e]
            | otherwise = inlinePerformIO $ withForeignPtr x $ \p -> walk e x p s l s

          STRICT6(walk)
          walk e x p s l i = assert (i < l) $! do -- e non-zero => we can't make it to the end without seeing a high byte
              c <- peekByteOff p i 
              case () of 
              _ | c <= 0x80 -> walk e x p s l (i+1)
                | l' > big  -> return $! PS x s l'  0  : run x i       (l-l')  e
                | otherwise -> let e' = extras x i (extraChunkSize - l') in 
                               return $! PS x s big e' : run x (s+big) (l-big) (e-e')

toLazy :: Rope -> L.Buffer
toLazy r = L.fromChunks (toList r)
{-# INLINE toLazyBuffer #-}

-- | Consume the chunks of a lazy Buffer with a natural right fold.
foldrChunks :: (Buffer -> a -> a) -> a -> Rope -> a
foldrChunks f z (Rope r) = foldr f z r 
{-# INLINE foldrChunks #-}

-- | Consume the chunks of a lazy Buffer with a strict, tail-recursive,
-- accumulating left fold.
foldlChunks :: (a -> Buffer -> a) -> a -> Rope -> a
foldlChunks f z (Rope r) = foldl f z r
{-# INLINE foldlChunks #-}


instance Eq Rope where 
    Rope a == Rope b = sa == sb && ea == eb && eq (F.viewl a) (F.viewl b)
        where MEASURED(a,b)

instance Ord Rope where
    where compare = cmp (F.viewl a) (F.viewl b)

instance Monoid Buffer where
    mempty  = empty
    mappend = append
    mconcat = concat

eq :: ViewL (FingerTree Buffer) Buffer -> ViewL (FingerTree Buffer) Buffer -> Bool
eq EmptyL    EmptyL    = True
eq EmptyL    _         = False
eq _         EmptyL    = False
eq (a :< as) (b :< bs) =
  case compare (S.length a) (S.length b) of
    LT -> a == (S.take (S.length a) b) && eq (F.viewl as) (S.drop (S.length a) b :< bs)
    EQ -> a == b                       && eq (F.viewl as) (F.viewl bs)
    GT -> (S.take (S.length b) a) == b && eq (S.drop (S.length b) a :< as) (F.viewl bs)

cmp :: ViewL (FingerTree Buffer) -> ViewL (FingerTree Buffer) -> Ordering
cmp EmptyL    EmptyL    = EQ
cmp EmptyL    _         = LT
cmp _         EmptyL    = GT
cmp (a :< as) (b :< bs) =
  case compare (S.length a) (S.length b) of
    LT -> case compare a (S.take (S.length a) b) of
            EQ     -> cmp (F.viewl as) (S.drop (S.length a) b :< bs)
            result -> result
    EQ -> case compare a b of
            EQ     -> cmp (F.viewl as) (F.viewl bs)
            result -> result
    GT -> case compare (S.take (S.length b) a) b of
            EQ     -> cmp (S.drop (S.length b) a) :< as) (F.viewl bs)
            result -> result

------------------------------------------------------------------------

-- The representation chunks. When we have to convert from
-- a lazy list to the chunked representation, then by default we use this
-- chunk size. Some functions give you more control over the chunk size.
--
-- Measurements here:
--  http://www.cse.unsw.edu.au/~dons/tmp/chunksize_v_cache.png
--
-- indicate that a value around 0.5 to 1 x your L2 cache is best.
-- The following value assumes people have something greater than 128k,
-- and need to share the cache with other programs.

-- | Currently set to 32k, less the memory management overhead
defaultChunkSize :: Int
defaultChunkSize = 32 * k - chunkOverhead
   where k = 1024
-- | Currently set to 4k, less the memory management overhead

smallChunkSize :: Int
smallChunkSize = 4 * k - chunkOverhead
   where k = 1024

-- when adding chunks to the tree that have multibyte tails, very small strings favor fast splitting/indexing.
-- | Currently set to try to fit in a cache line, less the memory management overhead
extraChunkSize :: Int
extraChunkSize = 128 - chunkOverhead

-- | The memory management overhead. Currently this is tuned for GHC only.
chunkOverhead :: Int
chunkOverhead = 2 * sizeOf (undefined :: Int)
