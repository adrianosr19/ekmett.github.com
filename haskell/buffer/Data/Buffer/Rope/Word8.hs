{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
{-# OPTIONS_HADDOCK prune #-}

-- |
-- Module      : Data.Buffer.Rope.Word8
-- Copyright   : (c) Don Stewart 2006
--               (c) Duncan Coutts 2006
--               (c) Edward Kmett 2010
-- License     : BSD-style
--
-- Maintainer  : ekmett@gmail.com
-- Stability   : experimental
-- Portability : portable
-- 
-- Some operations, such as concat, append, reverse and cons, have
-- better complexity than their "Data.Buffer" equivalents, due to
-- optimisations resulting from the fingertree spine. 
--
-- This module is intended to be imported @qualified@, to avoid name
-- clashes with "Prelude" functions.  eg.
--
-- > import qualified Data.Buffer.Rope.Word8 as R
--
-- Original GHC implementation by Bryan O\'Sullivan.
-- Rewritten to use 'Data.Array.Unboxed.UArray' by Simon Marlow.
-- Rewritten to support slices and use 'Foreign.ForeignPtr.ForeignPtr'
-- by David Roundy.
-- Polished and extended by Don Stewart.
-- Lazy variant by Duncan Coutts and Don Stewart.
-- A number of FingerTree algorithms are by Ross Paterson and Louis Wasserman
-- Converted to use a fingertree by Edward Kmett

module Data.Buffer.Rope.Word8 (
        -- * The @Buffer@ type
        Rope,                   -- instances: Eq, Ord, Show, Read, Data, Typeable

        -- * Introducing and eliminating 'Buffer's
        empty,                  -- :: Rope
        singleton,              -- :: Word8   -> Rope
        pack,                   -- :: [Word8] -> Rope
        unpack,                 -- :: Rope -> [Word8]
        fromChunks,             -- :: [Buffer] -> Rope
        toChunks,               -- :: Rope -> [Buffer]

        -- * Basic interface
        cons,                   -- :: Word8 -> Rope -> Rope
        snoc,                   -- :: Rope -> Word8 -> Rope
        append,                 -- :: Rope -> Rope -> Rope
        head,                   -- :: Rope -> Word8
        tail,                   -- :: Rope -> Rope
        uncons,                 -- :: Rope -> Maybe (Word8, Rope)
        viewl,                  -- :: Rope -> ViewL Rope Word8
        last,                   -- :: Rope -> Word8
        init,                   -- :: Rope -> Rope
        unsnoc,                 -- :: Rope -> Maybe (Rope, Word8)
        viewr,                  -- :: Rope -> ViewR Rope Word8
        null,                   -- :: Rope -> Bool
        length,                 -- :: Rope -> Int

        -- * Transforming Buffers
        map                    -- :: (Word8 -> Word8) -> Rope -> Rope
        reverse,                -- :: Rope -> Rope
        intersperse,            -- :: Word8 -> Rope -> Rope
        intercalate,            -- :: Rope -> [Rope] -> Rope
        transpose,              -- :: [Rope] -> [Rope]

        -- * Reducing 'Buffer's (folds)
        foldl,                  -- :: (a -> Word8 -> a) -> a -> Rope -> a
        foldl',                 -- :: (a -> Word8 -> a) -> a -> Rope -> a
        foldl1,                 -- :: (Word8 -> Word8 -> Word8) -> Rope -> Word8
        foldl1',                -- :: (Word8 -> Word8 -> Word8) -> Rope -> Word8
        foldr,                  -- :: (Word8 -> a -> a) -> a -> Rope -> a
        foldr1,                 -- :: (Word8 -> Word8 -> Word8) -> Rope -> Word8

        -- ** Special folds
        concat,                 -- :: [Rope] -> Rope
        concatMap,              -- :: (Word8 -> Rope) -> Rope -> Rope
        any,                    -- :: (Word8 -> Bool) -> Rope -> Bool
        all,                    -- :: (Word8 -> Bool) -> Rope -> Bool
        maximum,                -- :: Rope -> Word8
        minimum,                -- :: Rope -> Word8
{-

        -- * Building Buffers
        -- ** Scans
        scanl,                  -- :: (Word8 -> Word8 -> Word8) -> Word8 -> Rope -> Rope
        scanl1,                 -- :: (Word8 -> Word8 -> Word8) -> Rope -> Rope
        scanr,                  -- :: (Word8 -> Word8 -> Word8) -> Word8 -> Rope -> Rope
        scanr1,                 -- :: (Word8 -> Word8 -> Word8) -> Rope -> Rope

        -- ** Accumulating maps
        mapAccumL,              -- :: (acc -> Word8 -> (acc, Word8)) -> acc -> Rope -> (acc, Rope)
        mapAccumR,              -- :: (acc -> Word8 -> (acc, Word8)) -> acc -> Rope -> (acc, Rope)

        -- ** Infinite Buffers
        replicate,              -- :: Int -> Word8 -> Rope
        replicateBuffer,        -- :: Int -> Buffer -> Rope

        -- ** Unfolding Buffers
        unfoldr,                -- :: (a -> Maybe (Word8, a)) -> a -> Rope

        -- * Substrings

        -- ** Breaking strings
        take,                   -- :: Int -> Rope -> Rope
        drop,                   -- :: Int -> Rope -> Rope
        splitAt,                -- :: Int -> Rope -> (Rope, Rope)

        takeWhile,              -- :: (Word8 -> Bool) -> Rope -> Rope
        dropWhile,              -- :: (Word8 -> Bool) -> Rope -> Rope
        span,                   -- :: (Word8 -> Bool) -> Rope -> (Rope, Rope)
        break,                  -- :: (Word8 -> Bool) -> Rope -> (Rope, Rope)

        group,                  -- :: Rope -> [Rope]
        groupBy,                -- :: (Word8 -> Word8 -> Bool) -> Rope -> [Rope]
        inits,                  -- :: Rope -> [Rope]
        tails,                  -- :: Rope -> [Rope]

        -- ** Breaking into many substrings
        split,                  -- :: Word8 -> Rope -> [Rope]
        splitWith,              -- :: (Word8 -> Bool) -> Rope -> [Rope]

        -- * Predicates
        isPrefixOf,             -- :: Rope -> Rope -> Bool
        isSuffixOf,             -- :: Rope -> Rope -> Bool

        -- * Searching Ropes

        -- ** Searching by equality
        elem,                   -- :: Word8 -> Rope -> Bool
        notElem,                -- :: Word8 -> Rope -> Bool

        -- ** Searching with a predicate
        find,                   -- :: (Word8 -> Bool) -> Rope -> Maybe Word8
        filter,                 -- :: (Word8 -> Bool) -> Rope -> Rope
        partition,              -- :: (Word8 -> Bool) -> Rope -> (Rope, Rope)

        -- * Indexing Ropes
        index,                  -- :: Rope -> Int -> Word8
        elemIndex,              -- :: Word8 -> Rope -> Maybe Int
        elemIndices,            -- :: Word8 -> Rope -> [Int]
        findIndex,              -- :: (Word8 -> Bool) -> Rope -> Maybe Int
        findIndices,            -- :: (Word8 -> Bool) -> Rope -> [Int]
        count,                  -- :: Word8 -> Rope -> Int

        -- * Zipping and unzipping Ropes
        zip,                    -- :: Rope -> Rope -> [(Word8, Word8)]
        zipWith,                -- :: (Word8 -> Word8 -> c) -> Rope -> Rope -> [c]
        unzip,                  -- :: [(Word8,Word8)] -> (Rope, Rope)

        -- * Ordered Ropes
--        sort,                   -- :: Rope -> Rope

        -- * Low level conversions
        -- ** Copying Ropes
        copy,                   -- :: Rope -> Rope
--        defrag,                -- :: Rope -> Rope

        -- * I\/O with 'Rope's

        -- ** Standard input and output
        getContents,            -- :: IO Rope
        putStr,                 -- :: Rope -> IO ()
        putStrLn,               -- :: Rope -> IO ()
        interact,               -- :: (Rope -> Rope) -> IO ()

        -- ** Files
        readFile,               -- :: FilePath -> IO Rope
        writeFile,              -- :: FilePath -> Rope -> IO ()
        appendFile,             -- :: FilePath -> Rope -> IO ()

        -- ** I\/O with Handles
        hGetContents,           -- :: Handle -> IO Rope
        hGet,                   -- :: Handle -> Int -> IO Rope
        hGetNonBlocking,        -- :: Handle -> Int -> IO Rope
        hPut,                   -- :: Handle -> Rope -> IO ()
        hPutStr,                -- :: Handle -> Rope -> IO ()
-}

  ) where

import Prelude hiding
    (reverse,head,tail,last,init,null,length,map,lines,foldl,foldr,unlines
    ,concat,any,take,drop,splitAt,takeWhile,dropWhile,span,break,elem,filter,maximum
    ,minimum,all,concatMap,foldl1,foldr1,scanl, scanl1, scanr, scanr1
    ,repeat, cycle, interact, iterate,readFile,writeFile,appendFile,replicate
    ,getContents,getLine,putStr,putStrLn ,zip,zipWith,unzip,notElem)

import qualified Data.List as L  -- L for list/lazy
import Data.Buffer.Rope.Internal

import Data.Buffer.Internal (Buffer(..))
import qualified Data.Buffer.Word8 as P (Buffer) -- type name only
import qualified Data.Buffer.Word8 as S -- S for strict (hmm...)
import qualified Data.Buffer.Internal as S
import qualified Data.Buffer.Unsafe as S

import qualified Data.Buffer.Internal.FingerTree as F
import qualified Data.Foldable as F

import Data.Monoid              (Monoid(..))

import Data.Word                (Word8)
import Data.Int                 (Int64)
import System.IO                (Handle,stdin,stdout,openBinaryFile,IOMode(..)
                                ,hClose,hWaitForInput,hIsEOF)
import System.IO.Error          (mkIOError, illegalOperationErrorType)
import System.IO.Unsafe
#ifndef __NHC__
import Control.Exception        (bracket)
#else
import IO		        (bracket)
#endif

import Foreign.ForeignPtr       (withForeignPtr)
import Foreign.Ptr
import Foreign.Storable

-- -----------------------------------------------------------------------------
--
-- Useful macros, until we have bang patterns
--

#define STRICT1(f) f a | a `seq` False = undefined
#define STRICT2(f) f a b | a `seq` b `seq` False = undefined
#define STRICT3(f) f a b c | a `seq` b `seq` c `seq` False = undefined
#define STRICT4(f) f a b c d | a `seq` b `seq` c `seq` d `seq` False = undefined
#define STRICT5(f) f a b c d e | a `seq` b `seq` c `seq` d `seq` e `seq` False = undefined

-- -----------------------------------------------------------------------------


-- this will rip the input up into chunks from 112 byte to 64k long each depending on 
pack :: [Word8] -> Rope
pack ws = L.foldr (fromBuffer . S.pack) empty (chunks defaultChunkSize ws)
  where
    chunks :: Int -> [a] -> [[a]]
    chunks _    [] = []
    chunks size xs = case L.splitAt size xs of
                      (xs', xs'') -> xs' : chunks size xs''

unpack :: Rope -> [Word8]
unpack (Rope r) = concatMap S.unpack (F.toList r)

fromChunks :: [Buffer] -> Rope
fromChunks = F.foldMap fromBuffer

toChunks :: Rope -> [Buffer]
toChunks (Rope r) = F.toList r


-- | Assume that the buffer is small enough that it doesn't need splitting
consBuffer' :: Buffer -> Rope -> Rope
consBuffer' a@(PS _ _ l _) (Rope as) 
    | l == 0 = Rope as 
    | otherwise = Rope (F.cons a as)

snocBuffer' :: Rope -> Buffer -> Rope
snocBuffer' (Rope as) a@(PS _ _ l _) 
    | l == 0 = Rope as
    | otherwise = Rope (F.snoc as a)

-- | /O(1)/ Convert a 'Word8' into a 'Buffer'
singleton :: Word8 -> Rope
singleton x = Rope (F.singleton (S.singleton x))
{-# INLINE singleton #-}

-- | /O(n)/ Convert a '[Word8]' into a 'Buffer'. 
pack :: [Word8] -> Buffer
pack ws = L.foldr (Chunk . S.pack) Empty (chunks defaultChunkSize ws)
  where
    chunks :: Int -> [a] -> [[a]]
    chunks _    [] = []
    chunks size xs = case L.splitAt size xs of
                      (xs', xs'') -> xs' : chunks size xs''

-- | /O(n)/ Converts a 'Buffer' to a '[Word8]'.
unpack :: Buffer -> [Word8]
unpack cs = L.concatMap S.unpack (toChunks cs)
--TODO: we can do better here by integrating the concat with the unpack

-- | /O(c)/ Convert a list of strict 'Buffer' into a lazy 'Buffer'
fromChunks :: [P.Buffer] -> Buffer
fromChunks cs = L.foldr chunk Empty cs

-- | /O(n)/ Convert a lazy 'Buffer' into a list of strict 'Buffer'
toChunks :: Buffer -> [P.Buffer]
toChunks cs = foldrChunks (:) [] cs

------------------------------------------------------------------------

-- Basic interface

-- | /O(1)/ Test whether a 'Buffer' is empty.
null :: Rope -> Bool
null Empty = True
null _     = False
{-# INLINE null #-}

-- | /O(n\/c)/ 'length' returns the length of a 'Buffer' as an 'Int'
length :: Rope -> Int
length = size
{-# INLINE length #-}

-- | /O(1)/ 'cons' is analogous to '(:)' for lists.
cons :: Word8 -> Rope -> Rope
cons w (Rope F.Empty) = singleton w
cons w (Rope F.Single a) | S.length a < 16 = F.singleton (S.cons w a))
cons w (Rope (F.Deep s e (One a) m sf)) | S.length a < 16 = Rope (F.Deep (s+1) (e+S.extra w) (One (S.cons w a)) m sf)
cons w (Rope (F.Deep s e (Two a b) m sf)) | S.length a < 16 = Rope (F.Deep (s+1) (e+S.extra w) (Two (S.cons w a) b) m sf)
cons w (Rope (F.Deep s e (Three a b c) m sf)) | S.length a < 16 = Rope (F.Deep (s+1) (e+S.extra w) (Three (S.cons w a) b c) m sf)
cons w (Rope (F.Deep s e (Four a b c d) m sf)) | S.length a < 16 = Rope (F.Deep (s+1) (e+S.extra w) (Four (S.cons w a) b c d) m sf)
cons w r = Rope (S.singleton a `F.cons` r)
{-# INLINE cons #-}

-- | /O(1)/ Append a byte to the end of a 'Rope'
snoc :: Buffer -> Word8 -> Buffer
snoc (Rope F.Empty) = singleton w 
snoc (Rope F.Single a) w | S.length a < 16 = F.singleton (S.snoc a w)
snoc (Rope (F.Deep s e pr m (One a))) w | S.length a < 16 = Rope (F.Deep (s+1) (e+S.extra w) pr m (One (S.snoc a w)))
snoc (Rope (F.Deep s e pr m (Two a b))) w | S.length b < 16 = Rope (F.Deep (s+1) (e+S.extra w) pr m (Two a (S.snoc b w)))
snoc (Rope (F.Deep s e pr m (Three a b c))) w | S.length c < 16 = Rope (F.Deep (s+1) (e+S.extra w) pr m (Three a b (S.snoc c w)))
snoc (Rope (F.Deep s e pr m (Four a b c d))) w | S.length d < 16 = Rope (F.Deep (s+1) (e+S.extra w) pr m (Four a b c (S.snoc d w)))
snoc r w = Rope (r `F.snoc` S.singleton a)
{-# INLINE snoc #-}

-- | /O(1)/ Extract the first element of a 'Rope', which must be non-empty.
head (Chunk c _) = S.unsafeHead c
head :: Rope -> Word8
head (Rope r) = S.unsafeHead (F.head r)
{-# INLINE head #-}

-- | /O(1)/ Extract the head and tail of a 'Rope', returning Nothing
-- if it is empty.
uncons :: Rope -> Maybe (Word8, Rope)
uncons (Rope r) = case F.viewl r of
        a :< as -> case S.viewl a of
            b :< nbs -> Just (b, bs `consBuffer'` Rope as) 
        EmptyL -> EmptyR
{-# INLINE uncons #-}

-- | /O(1)/ Extract the head and tail of a 'Rope' as a 'ViewL'
viewl :: Rope -> ViewL Rope Word8
viewl (Rope r) = case F.viewl r of 
        a :< as -> case S.viewl a of
            b :< bs -> b :< (bs `consBuffer'` Rope as)
        EmptyL  -> EmptyL
{-# INLINE viewl #-}



-- | /O(1)/ Extract the elements after the head of a 'Rope', which must be non-empty.
tail (Rope r) = case F.viewl r of
        a :> as -> S.tail a `consBuffer'` Rope as
        EmptyL -> errorEmptyList "tail"
{-# INLINE tail #-}


-- | /O(1)/ Extract everything preceding the last element, and the last element of a 'Rope', returning Nothing if it is empty
unsnoc :: Rope -> Maybe (Rope, Word8)
unsnoc (Rope r) = case F.viewl r of
        as :> a -> S.viewr a of
            bs :> b -> Just (Rope as `snocBuffer'` bs, b)
        EmptyR -> EmptyR
{-# INLINE unsnoc #-}

-- | /O(1)/ Extract the init and last of a 'Rope' as a 'ViewR'
viewr :: Rope -> ViewR Rope Word8
viewr (Rope r) = case F.viewr r of
        as :> a -> S.viewr a of
            bs :> b -> (Rope as `snocBuffer'` bs) :> b
        EmptyR -> EmptyR
{-# INLINE viewr #-}
        
-- | /O(1)/ Extract the last element of a Buffer, which must be finite and non-empty.
last :: Rope -> Word8
last (Rope r) = S.unsafeLast (F.last r)
{-# INLINE last #-}

-- | /O(1)/ Return all the elements of a 'Rope' except the last one. Requires the 'Rope' to be non-empty.
init (Rope r) = case F.viewR r of
        as :< a -> Rope as `snocBuffer'` S.init a
        EmptyR -> errorEmptyList "init"
{-# INLINE init #-}

-- | /O(log(min(n,m)))/ Append two Buffers
append :: Rope -> Rope -> Rope
append (Rope a) (Rope b) = Rope (a `mappend` b)
{-# INLINE append #-}

-- ---------------------------------------------------------------------
-- Transformations

-- | /O(n)/ 'map' @f xs@ is the Buffer obtained by applying @f@ to each
-- element of @xs@.
map :: (Word8 -> Word8) -> Rope -> Rope
map f = foldMap (fromBuffer . map f)
{-# INLINE map #-}

-- | /O(n)/. The reverse of a 'Rope'.
reverse :: Rope -> Rope
reverse (Rope xs) = Rope (reverseTree S.reverse xs)
{-# INLINE reverse #-}

reverseTree :: (a -> a) -> FingerTree a -> FingerTree a
reverseTree _ F.Empty = F.Empty
reverseTree f (F.Single x) = F.Single (f x)
reverseTree f (F.Deep s e pr m sf) =
    F.Deep s e (reverseDigit f sf)
        (reverseTree (reverseNode f) m)
        (reverseDigit f pr)

{-# INLINE reverseDigit #-}
reverseDigit :: (a -> a) -> Digit a -> Digit a
reverseDigit f (One a) = One (f a)
reverseDigit f (Two a b) = Two (f b) (f a)
reverseDigit f (Three a b c) = Three (f c) (f b) (f a)
reverseDigit f (Four a b c d) = Four (f d) (f c) (f b) (f a)

reverseNode :: (a -> a) -> Node a -> Node a
reverseNode f (Node2 s e a b) = Node2 s e (f b) (f a)
reverseNode f (Node3 s e a b c) = Node3 s e (f c) (f b) (f a)

-- | The 'intersperse' function takes a 'Word8' and a 'Buffer' and
-- \`intersperses\' that byte between the elements of the 'Buffer'.
-- It is analogous to the intersperse function on Lists.
intersperse :: Word8 -> Rope -> Rope
intersperse w (Rope r) = case f.viewL r of
    EmptyL -> empty
    c :< cs -> intersperse w c `consBuffer` mapBuffer intersperse' cs
  where intersperse' :: S.Buffer -> S.Buffer
        intersperse' (S.PS fp o l e) =
          S.unsafeCreate' (2*l) $ \p' -> withForeignPtr fp $ \p -> do
            poke p' w
            S.c_intersperse (p' `plusPtr` 1) (p `plusPtr` o) (fromIntegral l) w
            return $! e + l * S.extra w

-- | The 'transpose' function transposes the rows and columns of its
-- 'Buffer' argument.
transpose :: [Rope] -> [Rope]
transpose css = L.map pack (L.transpose (L.map unpack css))
--TODO: make this fast

-- ---------------------------------------------------------------------
-- Reducing 'Buffer's

-- | 'foldl', applied to a binary operator, a starting value (typically
-- the left-identity of the operator), and a Buffer, reduces the
-- Buffer using the binary operator, from left to right.
foldl :: (a -> Word8 -> a) -> a -> Rope -> a
foldl f z = foldlChunks (S.foldl f z) z
{-# INLINE foldl #-}

-- | 'foldl\'' is like 'foldl', but strict in the accumulator.
foldl' :: (a -> Word8 -> a) -> a -> Rope -> a
foldl' f z = foldlChunks' (S.foldl' f z) z
{-# INLINE foldl' #-}

-- | 'foldr', applied to a binary operator, a starting value
-- (typically the right-identity of the operator), and a Buffer,
-- reduces the Buffer using the binary operator, from right to left.
foldr :: (Word8 -> a -> a) -> a -> Rope -> a
foldr k z = foldrChunks (S.foldl f z) z
{-# INLINE foldr #-}

-- | 'foldl1' is a variant of 'foldl' that has no starting value
-- argument, and thus must be applied to non-empty 'Buffers'.
-- This function is subject to array fusion.
foldl1 :: (Word8 -> Word8 -> Word8) -> Rope -> Word8
foldl1 f r = case viewl r of 
    EmptyL -> errorEmptyList "foldl1"
    a :< as -> foldlChunks f (S.foldl f (S.unsafeHead a) (S.unsafeTail a)) as

-- | 'foldl1\'' is like 'foldl1', but strict in the accumulator.
foldl1' :: (Word8 -> Word8 -> Word8) -> Buffer -> Word8
foldl1' f r = case viewl r of 
    EmptyL -> errorEmptyList "foldl1'"
    a :< as -> foldlChunks' f (S.foldl' f (S.unsafeHead a) (S.unsafeTail a)) as

-- | 'foldr1' is a variant of 'foldr' that has no starting value argument,
-- and thus must be applied to non-empty 'Buffer's
foldr1 :: (Word8 -> Word8 -> Word8) -> Buffer -> Word8
foldr1 f r = case viewr r of
    EmptyR -> errorEmptyList "foldr1"
    as :> a -> foldrChunks f (S.foldr f (S.unsafeLast a)) (S.unsafeInit a)) as

-- | 'foldr1\'' is like 'foldr1', but strict in the accumulator.
foldr1' :: (Word8 -> Word8 -> Word8) -> Buffer -> Word8
foldr1' f r = case viewr r of
    EmptyR -> errorEmptyList "foldr1"
    as :> a -> foldrChunks' f (S.foldr' f (S.unsafeLast a)) (S.unsafeInit a)) as

-- ---------------------------------------------------------------------
-- Special folds

-- | /O(n)/ Concatenate a list of Buffers.
concat :: [Rope] -> Rope
concat = L.foldr append empty

-- | Map a function over a 'Rope' and concatenate the results
concatMap :: (Word8 -> Rope) -> Rope -> Rope
concatMap f = foldMap (mconcat . S.unpackWith f)

-- | /O(n)/ Applied to a predicate and a Rope, 'any' determines if
-- any element of the 'Rope' satisfies the predicate.
any :: (Word8 -> Bool) -> Rope -> Bool
any f (Rope r) = F.any (S.any f) r
{-# INLINE any #-}
-- todo fuse

-- | /O(n)/ Applied to a predicate and a 'Rope', 'all' determines
-- if all elements of the 'Rope' satisfy the predicate.
all :: (Word8 -> Bool) -> Buffer -> Bool
all f (Rope r) = F.all (S.all f) r
{-# INLINE all #-}
-- todo fuse

-- | /O(n)/ 'maximum' returns the maximum value from a 'Rope'
maximum :: Rope -> Word8
maximum (Rope r) = case F.viewL r of
    EmptyL -> errorEmptyList "maximum"
    c :< cs -> foldlChunks (\n c' -> n `max` S.maximum c') (S.maximum c) cs
{-# INLINE maximum #-}

-- | /O(n)/ 'minimum' returns the minimum value from a 'Rope'
minimum :: Rope -> Word8
minimum (Rope r) = case F.viewR r of
    EmptyL -> errorEmptyList "minimum"
    c :< cs -> foldlChunks (\n c' -> n `min` S.minimum c') (S.minimum c) cs
{-# INLINE minimum #-}

-- | The 'mapAccumBufferL' function behaves like a combination of 'map' and
-- 'foldl'; it applies a function to each 'Buffer' in the 'Rope'
-- passing an accumulating parameter from left to right, and returning a
-- final value of this accumulator together with a new 'Rope' formed 
-- by gluing together the buffers, and splitting the ones that are too large.
mapAccumBufferL :: (acc -> Buffer -> (acc, Buffer)) -> acc -> Rope -> (acc, Rope)
mapAccumBufferL f s0 r = go s0 (viewl r)
    where
        go s EmptyL = (s, empty)
        go s (c :< cs) = (s'', c' `consBuffer` cs')
            where (s', c') = S.mapAccumL f s c
                  (s'', cs') = go s' cs

-- | The 'mapAccumL' function behaves like a combination of 'map' and
-- 'foldl'; it applies a function to each element of a Buffer,
-- passing an accumulating parameter from left to right, and returning a
-- final value of this accumulator together with the new Buffer.
mapAccumL :: (acc -> Word8 -> (acc, Word8)) -> acc -> Rope -> (acc, Rope)
mapAccumL f = mapAccumBufferL (S.mapAccumL f)


-- | The 'mapAccumR' function behaves like a combination of 'map' and
-- 'foldr'; it applies a function to each element of a Buffer,
-- passing an accumulating parameter from right to left, and returning a
-- final value of this accumulator together with the new Buffer.
mapAccumR :: (acc -> Word8 -> (acc, Word8)) -> acc -> Buffer -> (acc, Buffer)
mapAccumR f s0 cs0 = go s0 cs0
  where
    go s Empty        = (s, Empty)
    go s (Chunk c cs) = (s'', Chunk c' cs')
        where (s'', c') = S.mapAccumR f s' c
              (s', cs') = go s cs

-- | The 'mapAccumBufferL' function behaves like a combination of 'map' and
-- 'foldr'; it applies a function to each 'Buffer' in the 'Rope'
-- passing an accumulating parameter from right to left, and returning a
-- final value of this accumulator together with a new 'Rope' formed 
-- by gluing together the buffers, and splitting the ones that are too large.
mapAccumBufferR :: (acc -> Buffer -> (acc, Buffer)) -> acc -> Rope -> (acc, Rope)
mapAccumBufferR f s0 r = go s0 (viewr r)
    where
        go s EmptyR = (s, empty)
        go s (cs :> c) = (s'', cs' `snocBuffer` c)
            where (s', c') = S.mapAccumR f s c
                  (s'', cs') = go s' cs

-- ---------------------------------------------------------------------
-- Building Buffers

-- | 'scanl' is similar to 'foldl', but returns a list of successive
-- reduced values from the left. This function will fuse.
--
-- > scanl f z [x1, x2, ...] == [z, z `f` x1, (z `f` x1) `f` x2, ...]
--
-- Note that
--
-- > last (scanl f z xs) == foldl f z xs.
scanl :: (Word8 -> Word8 -> Word8) -> Word8 -> Rope -> Rope
scanl f z = snd . foldl k (z,singleton z)
 where
    k (c,acc) a = let n = f c a in (n, acc `snoc` n)
{-# INLINE scanl #-}

-- ---------------------------------------------------------------------
-- Unfolds and replicates

-- | @'iterate' f x@ returns an infinite Buffer of repeated applications
-- of @f@ to @x@:
--
-- > iterate f x == [x, f x, f (f x), ...]
--
iterate :: (Word8 -> Word8) -> Word8 -> Buffer
iterate f = unfoldr (\x -> case f x of x' -> x' `seq` Just (x', x'))

-- | @'repeat' x@ is an infinite Buffer, with @x@ the value of every
-- element.
--
repeat :: Word8 -> Buffer
repeat w = cs where cs = Chunk (S.replicate smallChunkSize w) cs

-- | /O(n)/ @'replicate' n x@ is a Buffer of length @n@ with @x@
-- the value of every element.
--
replicate :: Int64 -> Word8 -> Buffer
replicate n w
    | n <= 0             = Empty
    | n < fromIntegral smallChunkSize = Chunk (S.replicate (fromIntegral n) w) Empty
    | r == 0             = cs -- preserve invariant
    | otherwise          = Chunk (S.unsafeTake (fromIntegral r) c) cs
 where
    c      = S.replicate smallChunkSize w
    cs     = nChunks q
    (q, r) = quotRem n (fromIntegral smallChunkSize)
    nChunks 0 = Empty
    nChunks m = Chunk c (nChunks (m-1))

-- | 'cycle' ties a finite Buffer into a circular one, or equivalently,
-- the infinite repetition of the original Buffer.
--
cycle :: Buffer -> Buffer
cycle Empty = errorEmptyList "cycle"
cycle cs    = cs' where cs' = foldrChunks Chunk cs' cs

-- | /O(n)/ The 'unfoldr' function is analogous to the List \'unfoldr\'.
-- 'unfoldr' builds a Buffer from a seed value.  The function takes
-- the element and returns 'Nothing' if it is done producing the
-- Buffer or returns 'Just' @(a,b)@, in which case, @a@ is a
-- prepending to the Buffer and @b@ is used as the next element in a
-- recursive call.
unfoldr :: (a -> Maybe (Word8, a)) -> a -> Buffer
unfoldr f s0 = unfoldChunk 32 s0
  where unfoldChunk n s =
          case S.unfoldrN n f s of
            (c, Nothing)
              | S.null c  -> Empty
              | otherwise -> Chunk c Empty
            (c, Just s')  -> Chunk c (unfoldChunk (n*2) s')

-- ---------------------------------------------------------------------
-- Substrings

-- | /O(n\/c)/ 'take' @n@, applied to a Buffer @xs@, returns the prefix
-- of @xs@ of length @n@, or @xs@ itself if @n > 'length' xs@.
take :: Int64 -> Buffer -> Buffer
take i _ | i <= 0 = Empty
take i cs0         = take' i cs0
  where take' 0 _            = Empty
        take' _ Empty        = Empty
        take' n (Chunk c cs) =
          if n < fromIntegral (S.length c)
            then Chunk (S.take (fromIntegral n) c) Empty
            else Chunk c (take' (n - fromIntegral (S.length c)) cs)

-- | /O(n\/c)/ 'drop' @n xs@ returns the suffix of @xs@ after the first @n@
-- elements, or @[]@ if @n > 'length' xs@.
drop  :: Int64 -> Buffer -> Buffer
drop i p | i <= 0 = p
drop i cs0 = drop' i cs0
  where drop' 0 cs           = cs
        drop' _ Empty        = Empty
        drop' n (Chunk c cs) =
          if n < fromIntegral (S.length c)
            then Chunk (S.drop (fromIntegral n) c) cs
            else drop' (n - fromIntegral (S.length c)) cs

-- | /O(n\/c)/ 'splitAt' @n xs@ is equivalent to @('take' n xs, 'drop' n xs)@.
splitAt :: Int64 -> Buffer -> (Buffer, Buffer)
splitAt i cs0 | i <= 0 = (Empty, cs0)
splitAt i cs0 = splitAt' i cs0
  where splitAt' 0 cs           = (Empty, cs)
        splitAt' _ Empty        = (Empty, Empty)
        splitAt' n (Chunk c cs) =
          if n < fromIntegral (S.length c)
            then (Chunk (S.take (fromIntegral n) c) Empty 
                 ,Chunk (S.drop (fromIntegral n) c) cs)
            else let (cs', cs'') = splitAt' (n - fromIntegral (S.length c)) cs
                   in (Chunk c cs', cs'')


-- | 'takeWhile', applied to a predicate @p@ and a Buffer @xs@,
-- returns the longest prefix (possibly empty) of @xs@ of elements that
-- satisfy @p@.
takeWhile :: (Word8 -> Bool) -> Buffer -> Buffer
takeWhile f cs0 = takeWhile' cs0
  where takeWhile' Empty        = Empty
        takeWhile' (Chunk c cs) =
          case findIndexOrEnd (not . f) c of
            0                  -> Empty
            n | n < S.length c -> Chunk (S.take n c) Empty
              | otherwise      -> Chunk c (takeWhile' cs)

-- | 'dropWhile' @p xs@ returns the suffix remaining after 'takeWhile' @p xs@.
dropWhile :: (Word8 -> Bool) -> Buffer -> Buffer
dropWhile f cs0 = dropWhile' cs0
  where dropWhile' Empty        = Empty
        dropWhile' (Chunk c cs) =
          case findIndexOrEnd (not . f) c of
            n | n < S.length c -> Chunk (S.drop n c) cs
              | otherwise      -> dropWhile' cs

-- | 'break' @p@ is equivalent to @'span' ('not' . p)@.
break :: (Word8 -> Bool) -> Buffer -> (Buffer, Buffer)
break f cs0 = break' cs0
  where break' Empty        = (Empty, Empty)
        break' (Chunk c cs) =
          case findIndexOrEnd f c of
            0                  -> (Empty, Chunk c cs)
            n | n < S.length c -> (Chunk (S.take n c) Empty
                                  ,Chunk (S.drop n c) cs)
              | otherwise      -> let (cs', cs'') = break' cs
                                   in (Chunk c cs', cs'')

--
-- TODO
--
-- Add rules
--

{-
-- | 'breakByte' breaks its Buffer argument at the first occurence
-- of the specified byte. It is more efficient than 'break' as it is
-- implemented with @memchr(3)@. I.e.
-- 
-- > break (=='c') "abcd" == breakByte 'c' "abcd"
--
breakByte :: Word8 -> Buffer -> (Buffer, Buffer)
breakByte c (LPS ps) = case (breakByte' ps) of (a,b) -> (LPS a, LPS b)
  where breakByte' []     = ([], [])
        breakByte' (x:xs) =
          case P.elemIndex c x of
            Just 0  -> ([], x : xs)
            Just n  -> (P.take n x : [], P.drop n x : xs)
            Nothing -> let (xs', xs'') = breakByte' xs
                        in (x : xs', xs'')

-- | 'spanByte' breaks its Buffer argument at the first
-- occurence of a byte other than its argument. It is more efficient
-- than 'span (==)'
--
-- > span  (=='c') "abcd" == spanByte 'c' "abcd"
--
spanByte :: Word8 -> Buffer -> (Buffer, Buffer)
spanByte c (LPS ps) = case (spanByte' ps) of (a,b) -> (LPS a, LPS b)
  where spanByte' []     = ([], [])
        spanByte' (x:xs) =
          case P.spanByte c x of
            (x', x'') | P.null x'  -> ([], x : xs)
                      | P.null x'' -> let (xs', xs'') = spanByte' xs
                                       in (x : xs', xs'')
                      | otherwise  -> (x' : [], x'' : xs)
-}

-- | 'span' @p xs@ breaks the Buffer into two segments. It is
-- equivalent to @('takeWhile' p xs, 'dropWhile' p xs)@
span :: (Word8 -> Bool) -> Buffer -> (Buffer, Buffer)
span p = break (not . p)

-- | /O(n)/ Splits a 'Buffer' into components delimited by
-- separators, where the predicate returns True for a separator element.
-- The resulting components do not contain the separators.  Two adjacent
-- separators result in an empty component in the output.  eg.
--
-- > splitWith (=='a') "aabbaca" == ["","","bb","c",""]
-- > splitWith (=='a') []        == []
--
splitWith :: (Word8 -> Bool) -> Buffer -> [Buffer]
splitWith _ Empty          = []
splitWith p (Chunk c0 cs0) = comb [] (S.splitWith p c0) cs0

  where comb :: [P.Buffer] -> [P.Buffer] -> Buffer -> [Buffer]
        comb acc (s:[]) Empty        = revChunks (s:acc) : []
        comb acc (s:[]) (Chunk c cs) = comb (s:acc) (S.splitWith p c) cs
        comb acc (s:ss) cs           = revChunks (s:acc) : comb [] ss cs

{-# INLINE splitWith #-}

-- | /O(n)/ Break a 'Buffer' into pieces separated by the byte
-- argument, consuming the delimiter. I.e.
--
-- > split '\n' "a\nb\nd\ne" == ["a","b","d","e"]
-- > split 'a'  "aXaXaXa"    == ["","X","X","X",""]
-- > split 'x'  "x"          == ["",""]
-- 
-- and
--
-- > intercalate [c] . split c == id
-- > split == splitWith . (==)
-- 
-- As for all splitting functions in this library, this function does
-- not copy the substrings, it just constructs new 'Buffers' that
-- are slices of the original.
--
split :: Word8 -> Buffer -> [Buffer]
split _ Empty     = []
split w (Chunk c0 cs0) = comb [] (S.split w c0) cs0

  where comb :: [P.Buffer] -> [P.Buffer] -> Buffer -> [Buffer]
        comb acc (s:[]) Empty        = revChunks (s:acc) : []
        comb acc (s:[]) (Chunk c cs) = comb (s:acc) (S.split w c) cs
        comb acc (s:ss) cs           = revChunks (s:acc) : comb [] ss cs
{-# INLINE split #-}

{-
-- | Like 'splitWith', except that sequences of adjacent separators are
-- treated as a single separator. eg.
-- 
-- > tokens (=='a') "aabbaca" == ["bb","c"]
--
tokens :: (Word8 -> Bool) -> Buffer -> [Buffer]
tokens f = L.filter (not.null) . splitWith f
-}

-- | The 'group' function takes a Buffer and returns a list of
-- Buffers such that the concatenation of the result is equal to the
-- argument.  Moreover, each sublist in the result contains only equal
-- elements.  For example,
--
-- > group "Mississippi" = ["M","i","ss","i","ss","i","pp","i"]
--
-- It is a special case of 'groupBy', which allows the programmer to
-- supply their own equality test.
group :: Buffer -> [Buffer]
group Empty          = []
group (Chunk c0 cs0) = group' [] (S.group c0) cs0
  where 
    group' :: [P.Buffer] -> [P.Buffer] -> Buffer -> [Buffer]
    group' acc@(s':_) ss@(s:_) cs
      | S.unsafeHead s'
     /= S.unsafeHead s             = revNonEmptyChunks    acc  : group' [] ss cs
    group' acc (s:[]) Empty        = revNonEmptyChunks (s:acc) : []
    group' acc (s:[]) (Chunk c cs) = group' (s:acc) (S.group c) cs
    group' acc (s:ss) cs           = revNonEmptyChunks (s:acc) : group' [] ss cs

{-
TODO: check if something like this might be faster

group :: Buffer -> [Buffer]
group xs
    | null xs   = []
    | otherwise = ys : group zs
    where
        (ys, zs) = spanByte (unsafeHead xs) xs
-}

-- | The 'groupBy' function is the non-overloaded version of 'group'.
--
groupBy :: (Word8 -> Word8 -> Bool) -> Buffer -> [Buffer]
groupBy _ Empty          = []
groupBy k (Chunk c0 cs0) = groupBy' [] 0 (S.groupBy k c0) cs0
  where
    groupBy' :: [P.Buffer] -> Word8 -> [P.Buffer] -> Buffer -> [Buffer]
    groupBy' acc@(_:_) c ss@(s:_) cs
      | not (c `k` S.unsafeHead s)     = revNonEmptyChunks acc : groupBy' [] 0 ss cs
    groupBy' acc _ (s:[]) Empty        = revNonEmptyChunks (s : acc) : []
    groupBy' acc w (s:[]) (Chunk c cs) = groupBy' (s:acc) w' (S.groupBy k c) cs
                                           where w' | L.null acc = S.unsafeHead s
                                                    | otherwise  = w
    groupBy' acc _ (s:ss) cs           = revNonEmptyChunks (s : acc) : groupBy' [] 0 ss cs

{-
TODO: check if something like this might be faster

groupBy :: (Word8 -> Word8 -> Bool) -> Buffer -> [Buffer]
groupBy k xs
    | null xs   = []
    | otherwise = take n xs : groupBy k (drop n xs)
    where
        n = 1 + findIndexOrEnd (not . k (head xs)) (tail xs)
-}

-- | /O(n)/ The 'intercalate' function takes a 'Buffer' and a list of
-- 'Buffer's and concatenates the list after interspersing the first
-- argument between each element of the list.
intercalate :: Buffer -> [Buffer] -> Buffer
intercalate s = concat . (L.intersperse s)

-- ---------------------------------------------------------------------
-- Indexing Buffers

-- | /O(c)/ 'Buffer' index (subscript) operator, starting from 0.
index :: Buffer -> Int64 -> Word8
index _  i | i < 0  = moduleError "index" ("negative index: " ++ show i)
index cs0 i         = index' cs0 i
  where index' Empty     n = moduleError "index" ("index too large: " ++ show n)
        index' (Chunk c cs) n
          | n >= fromIntegral (S.length c) = 
              index' cs (n - fromIntegral (S.length c))
          | otherwise       = S.unsafeIndex c (fromIntegral n)

-- | /O(n)/ The 'elemIndex' function returns the index of the first
-- element in the given 'Buffer' which is equal to the query
-- element, or 'Nothing' if there is no such element. 
-- This implementation uses memchr(3).
elemIndex :: Word8 -> Buffer -> Maybe Int64
elemIndex w cs0 = elemIndex' 0 cs0
  where elemIndex' _ Empty        = Nothing
        elemIndex' n (Chunk c cs) =
          case S.elemIndex w c of
            Nothing -> elemIndex' (n + fromIntegral (S.length c)) cs
            Just i  -> Just (n + fromIntegral i)

{-
-- | /O(n)/ The 'elemIndexEnd' function returns the last index of the
-- element in the given 'Buffer' which is equal to the query
-- element, or 'Nothing' if there is no such element. The following
-- holds:
--
-- > elemIndexEnd c xs == 
-- > (-) (length xs - 1) `fmap` elemIndex c (reverse xs)
--
elemIndexEnd :: Word8 -> Buffer -> Maybe Int
elemIndexEnd ch (PS x s l) = inlinePerformIO $ withForeignPtr x $ \p ->
    go (p `plusPtr` s) (l-1)
  where
    STRICT2(go)
    go p i | i < 0     = return Nothing
           | otherwise = do ch' <- peekByteOff p i
                            if ch == ch'
                                then return $ Just i
                                else go p (i-1)
-}
-- | /O(n)/ The 'elemIndices' function extends 'elemIndex', by returning
-- the indices of all elements equal to the query element, in ascending order.
-- This implementation uses memchr(3).
elemIndices :: Word8 -> Buffer -> [Int64]
elemIndices w cs0 = elemIndices' 0 cs0
  where elemIndices' _ Empty        = []
        elemIndices' n (Chunk c cs) = L.map ((+n).fromIntegral) (S.elemIndices w c)
                             ++ elemIndices' (n + fromIntegral (S.length c)) cs

-- | count returns the number of times its argument appears in the Buffer
--
-- > count = length . elemIndices
--
-- But more efficiently than using length on the intermediate list.
count :: Word8 -> Buffer -> Int64
count w cs = foldlChunks (\n c -> n + fromIntegral (S.count w c)) 0 cs

-- | The 'findIndex' function takes a predicate and a 'Buffer' and
-- returns the index of the first element in the Buffer
-- satisfying the predicate.
findIndex :: (Word8 -> Bool) -> Buffer -> Maybe Int64
findIndex k cs0 = findIndex' 0 cs0
  where findIndex' _ Empty        = Nothing
        findIndex' n (Chunk c cs) =
          case S.findIndex k c of
            Nothing -> findIndex' (n + fromIntegral (S.length c)) cs
            Just i  -> Just (n + fromIntegral i)
{-# INLINE findIndex #-}

-- | /O(n)/ The 'find' function takes a predicate and a Buffer,
-- and returns the first element in matching the predicate, or 'Nothing'
-- if there is no such element.
--
-- > find f p = case findIndex f p of Just n -> Just (p ! n) ; _ -> Nothing
--
find :: (Word8 -> Bool) -> Buffer -> Maybe Word8
find f cs0 = find' cs0
  where find' Empty        = Nothing
        find' (Chunk c cs) = case S.find f c of
            Nothing -> find' cs
            Just w  -> Just w
{-# INLINE find #-}

-- | The 'findIndices' function extends 'findIndex', by returning the
-- indices of all elements satisfying the predicate, in ascending order.
findIndices :: (Word8 -> Bool) -> Buffer -> [Int64]
findIndices k cs0 = findIndices' 0 cs0
  where findIndices' _ Empty        = []
        findIndices' n (Chunk c cs) = L.map ((+n).fromIntegral) (S.findIndices k c)
                             ++ findIndices' (n + fromIntegral (S.length c)) cs

-- ---------------------------------------------------------------------
-- Searching Buffers

-- | /O(n)/ 'elem' is the 'Buffer' membership predicate.
elem :: Word8 -> Buffer -> Bool
elem w cs = case elemIndex w cs of Nothing -> False ; _ -> True

-- | /O(n)/ 'notElem' is the inverse of 'elem'
notElem :: Word8 -> Buffer -> Bool
notElem w cs = not (elem w cs)

-- | /O(n)/ 'filter', applied to a predicate and a Buffer,
-- returns a Buffer containing those characters that satisfy the
-- predicate.
filter :: (Word8 -> Bool) -> Buffer -> Buffer
filter p s = go s
    where
        go Empty        = Empty
        go (Chunk x xs) = chunk (S.filter p x) (go xs)
{-# INLINE filter #-}

{-
-- | /O(n)/ and /O(n\/c) space/ A first order equivalent of /filter .
-- (==)/, for the common case of filtering a single byte. It is more
-- efficient to use /filterByte/ in this case.
--
-- > filterByte == filter . (==)
--
-- filterByte is around 10x faster, and uses much less space, than its
-- filter equivalent
filterByte :: Word8 -> Buffer -> Buffer
filterByte w ps = replicate (count w ps) w
{-# INLINE filterByte #-}

{-# RULES
"Buffer specialise filter (== x)" forall x.
  filter ((==) x) = filterByte x

"Buffer specialise filter (== x)" forall x.
 filter (== x) = filterByte x
  #-}
-}

{-
-- | /O(n)/ A first order equivalent of /filter . (\/=)/, for the common
-- case of filtering a single byte out of a list. It is more efficient
-- to use /filterNotByte/ in this case.
--
-- > filterNotByte == filter . (/=)
--
-- filterNotByte is around 2x faster than its filter equivalent.
filterNotByte :: Word8 -> Buffer -> Buffer
filterNotByte w (LPS xs) = LPS (filterMap (P.filterNotByte w) xs)
-}

-- | /O(n)/ The 'partition' function takes a predicate a Buffer and returns
-- the pair of Buffers with elements which do and do not satisfy the
-- predicate, respectively; i.e.,
--
-- > partition p bs == (filter p xs, filter (not . p) xs)
--
partition :: (Word8 -> Bool) -> Buffer -> (Buffer, Buffer)
partition f p = (filter f p, filter (not . f) p)
--TODO: use a better implementation

-- ---------------------------------------------------------------------
-- Searching for substrings

-- | /O(n)/ The 'isPrefixOf' function takes two Buffers and returns 'True'
-- iff the first is a prefix of the second.
isPrefixOf :: Buffer -> Buffer -> Bool
isPrefixOf Empty _  = True
isPrefixOf _ Empty  = False
isPrefixOf (Chunk x xs) (Chunk y ys)
    | S.length x == S.length y = x == y  && isPrefixOf xs ys
    | S.length x <  S.length y = x == yh && isPrefixOf xs (Chunk yt ys)
    | otherwise                = xh == y && isPrefixOf (Chunk xt xs) ys
  where (xh,xt) = S.splitAt (S.length y) x
        (yh,yt) = S.splitAt (S.length x) y

-- | /O(n)/ The 'isSuffixOf' function takes two Buffers and returns 'True'
-- iff the first is a suffix of the second.
-- 
-- The following holds:
--
-- > isSuffixOf x y == reverse x `isPrefixOf` reverse y
--
isSuffixOf :: Buffer -> Buffer -> Bool
isSuffixOf x y = reverse x `isPrefixOf` reverse y
--TODO: a better implementation

-- ---------------------------------------------------------------------
-- Zipping

-- | /O(n)/ 'zip' takes two Buffers and returns a list of
-- corresponding pairs of bytes. If one input Buffer is short,
-- excess elements of the longer Buffer are discarded. This is
-- equivalent to a pair of 'unpack' operations.
zip :: Buffer -> Buffer -> [(Word8,Word8)]
zip = zipWith (,)

-- | 'zipWith' generalises 'zip' by zipping with the function given as
-- the first argument, instead of a tupling function.  For example,
-- @'zipWith' (+)@ is applied to two Buffers to produce the list of
-- corresponding sums.
zipWith :: (Word8 -> Word8 -> a) -> Buffer -> Buffer -> [a]
zipWith _ Empty     _  = []
zipWith _ _      Empty = []
zipWith f (Chunk a as) (Chunk b bs) = go a as b bs
  where
    go x xs y ys = f (S.unsafeHead x) (S.unsafeHead y)
                 : to (S.unsafeTail x) xs (S.unsafeTail y) ys

    to x Empty         _ _             | S.null x       = []
    to _ _             y Empty         | S.null y       = []
    to x xs            y ys            | not (S.null x)
                                      && not (S.null y) = go x  xs y  ys
    to x xs            _ (Chunk y' ys) | not (S.null x) = go x  xs y' ys
    to _ (Chunk x' xs) y ys            | not (S.null y) = go x' xs y  ys
    to _ (Chunk x' xs) _ (Chunk y' ys)                  = go x' xs y' ys

-- | /O(n)/ 'unzip' transforms a list of pairs of bytes into a pair of
-- Buffers. Note that this performs two 'pack' operations.
unzip :: [(Word8,Word8)] -> (Buffer,Buffer)
unzip ls = (pack (L.map fst ls), pack (L.map snd ls))
{-# INLINE unzip #-}

-- ---------------------------------------------------------------------
-- Special lists

-- | /O(n)/ Return all initial segments of the given 'Buffer', shortest first.
inits :: Buffer -> [Buffer]
inits = (Empty :) . inits'
  where inits' Empty        = []
        inits' (Chunk c cs) = L.map (\c' -> Chunk c' Empty) (L.tail (S.inits c))
                           ++ L.map (Chunk c) (inits' cs)

-- | /O(n)/ Return all final segments of the given 'Buffer', longest first.
tails :: Buffer -> [Buffer]
tails Empty         = Empty : []
tails cs@(Chunk c cs')
  | S.length c == 1 = cs : tails cs'
  | otherwise       = cs : tails (Chunk (S.unsafeTail c) cs')

-- ---------------------------------------------------------------------
-- Low level constructors

-- | /O(n)/ Make a copy of the 'Buffer' with its own storage.
--   This is mainly useful to allow the rest of the data pointed
--   to by the 'Buffer' to be garbage collected, for example
--   if a large string has been read in, and only a small part of it
--   is needed in the rest of the program.
copy :: Buffer -> Buffer
copy cs = foldrChunks (Chunk . S.copy) Empty cs
--TODO, we could coalese small blocks here
--FIXME: probably not strict enough, if we're doing this to avoid retaining
-- the parent blocks then we'd better copy strictly.

-- ---------------------------------------------------------------------

-- TODO defrag func that concatenates block together that are below a threshold
-- defrag :: Buffer -> Buffer

-- ---------------------------------------------------------------------
-- Lazy Buffer IO
--
-- Rule for when to close: is it expected to read the whole file?
-- If so, close when done. 
--

-- | Read entire handle contents /lazily/ into a 'Buffer'. Chunks
-- are read on demand, in at most @k@-sized chunks. It does not block
-- waiting for a whole @k@-sized chunk, so if less than @k@ bytes are
-- available then they will be returned immediately as a smaller chunk.
--
-- The handle is closed on EOF.
--
hGetContentsN :: Int -> Handle -> IO Buffer
hGetContentsN k h = lazyRead -- TODO close on exceptions
  where
    lazyRead = unsafeInterleaveIO loop

    loop = do
        c <- S.hGetNonBlocking h k
        --TODO: I think this should distinguish EOF from no data available
        -- the underlying POSIX call makes this distincion, returning either
        -- 0 or EAGAIN
        if S.null c
          then do eof <- hIsEOF h
                  if eof then hClose h >> return Empty
                         else hWaitForInput h (-1)
                           >> loop
          else do cs <- lazyRead
                  return (Chunk c cs)

-- | Read @n@ bytes into a 'Buffer', directly from the
-- specified 'Handle', in chunks of size @k@.
--
hGetN :: Int -> Handle -> Int -> IO Buffer
hGetN k h n | n > 0 = readChunks n
  where
    STRICT1(readChunks)
    readChunks i = do
        c <- S.hGet h (min k i)
        case S.length c of
            0 -> return Empty
            m -> do cs <- readChunks (i - m)
                    return (Chunk c cs)

hGetN _ _ 0 = return Empty
hGetN _ h n = illegalBufferSize h "hGet" n

-- | hGetNonBlockingN is similar to 'hGetContentsN', except that it will never block
-- waiting for data to become available, instead it returns only whatever data
-- is available. Chunks are read on demand, in @k@-sized chunks.
--
hGetNonBlockingN :: Int -> Handle -> Int -> IO Buffer
#if defined(__GLASGOW_HASKELL__)
hGetNonBlockingN k h n | n > 0= readChunks n
  where
    STRICT1(readChunks)
    readChunks i = do
        c <- S.hGetNonBlocking h (min k i)
        case S.length c of
            0 -> return Empty
            m -> do cs <- readChunks (i - m)
                    return (Chunk c cs)

hGetNonBlockingN _ _ 0 = return Empty
hGetNonBlockingN _ h n = illegalBufferSize h "hGetNonBlocking" n
#else
hGetNonBlockingN = hGetN
#endif

illegalBufferSize :: Handle -> String -> Int -> IO a
illegalBufferSize handle fn sz =
    ioError (mkIOError illegalOperationErrorType msg (Just handle) Nothing)
    --TODO: System.IO uses InvalidArgument here, but it's not exported :-(
    where
      msg = fn ++ ": illegal Buffer size " ++ showsPrec 9 sz []

-- | Read entire handle contents /lazily/ into a 'Buffer'. Chunks
-- are read on demand, using the default chunk size.
--
-- Once EOF is encountered, the Handle is closed.
--
hGetContents :: Handle -> IO Buffer
hGetContents = hGetContentsN defaultChunkSize

-- | Read @n@ bytes into a 'Buffer', directly from the specified 'Handle'.
--
hGet :: Handle -> Int -> IO Buffer
hGet = hGetN defaultChunkSize

-- | hGetNonBlocking is similar to 'hGet', except that it will never block
-- waiting for data to become available, instead it returns only whatever data
-- is available.
#if defined(__GLASGOW_HASKELL__)
hGetNonBlocking :: Handle -> Int -> IO Buffer
hGetNonBlocking = hGetNonBlockingN defaultChunkSize
#else
hGetNonBlocking = hGet
#endif

-- | Read an entire file /lazily/ into a 'Buffer'.
-- The Handle will be held open until EOF is encountered.
--
readFile :: FilePath -> IO Buffer
readFile f = openBinaryFile f ReadMode >>= hGetContents

-- | Write a 'Buffer' to a file.
--
writeFile :: FilePath -> Buffer -> IO ()
writeFile f txt = bracket (openBinaryFile f WriteMode) hClose
    (\hdl -> hPut hdl txt)

-- | Append a 'Buffer' to a file.
--
appendFile :: FilePath -> Buffer -> IO ()
appendFile f txt = bracket (openBinaryFile f AppendMode) hClose
    (\hdl -> hPut hdl txt)

-- | getContents. Equivalent to hGetContents stdin. Will read /lazily/
--
getContents :: IO Buffer
getContents = hGetContents stdin

-- | Outputs a 'Buffer' to the specified 'Handle'.
--
hPut :: Handle -> Buffer -> IO ()
hPut h cs = foldrChunks (\c rest -> S.hPut h c >> rest) (return ()) cs

-- | A synonym for @hPut@, for compatibility
--
hPutStr :: Handle -> Buffer -> IO ()
hPutStr = hPut

-- | Write a Buffer to stdout
putStr :: Buffer -> IO ()
putStr = hPut stdout

-- | Write a Buffer to stdout, appending a newline byte
--
putStrLn :: Buffer -> IO ()
putStrLn ps = hPut stdout ps >> hPut stdout (singleton 0x0a)

-- | The interact function takes a function of type @Buffer -> Buffer@
-- as its argument. The entire input from the standard input device is passed
-- to this function as its argument, and the resulting string is output on the
-- standard output device.
--
interact :: (Buffer -> Buffer) -> IO ()
interact transformer = putStr . transformer =<< getContents

-- ---------------------------------------------------------------------
-- Internal utilities

-- Common up near identical calls to `error' to reduce the number
-- constant strings created when compiled:
errorEmptyList :: String -> a
errorEmptyList fun = moduleError fun "empty Buffer"

moduleError :: String -> String -> a
moduleError fun msg = error ("Data.Buffer.Lazy." ++ fun ++ ':':' ':msg)


-- reverse a list of non-empty chunks into a lazy Buffer
revNonEmptyChunks :: [P.Buffer] -> Buffer
revNonEmptyChunks cs = L.foldl' (flip Chunk) Empty cs

-- reverse a list of possibly-empty chunks into a lazy Buffer
revChunks :: [P.Buffer] -> Buffer
revChunks cs = L.foldl' (flip chunk) Empty cs

-- | 'findIndexOrEnd' is a variant of findIndex, that returns the length
-- of the string if no element is found, rather than Nothing.
findIndexOrEnd :: (Word8 -> Bool) -> P.Buffer -> Int
findIndexOrEnd k (S.PS x s l _) = S.inlinePerformIO $ withForeignPtr x $ \f -> go (f `plusPtr` s) 0
  where
    STRICT2(go)
    go ptr n | n >= l    = return l
             | otherwise = do w <- peek ptr
                              if k w
                                then return n
                                else go (ptr `plusPtr` 1) (n+1)
{-# INLINE findIndexOrEnd #-}
