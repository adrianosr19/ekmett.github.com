{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, FlexibleContexts, GeneralizedNewtypeDeriving, ParallelListComp #-}
module Data.Monoid.Lexical.Words 
    ( Words
    , runWords
    , Lines
    , runLines
    , Unspaced(runUnspaced)
    , wordsFrom
    , linesFrom
    ) where

import Prelude hiding (lex)
import Data.Monoid.Lexical
import Data.Char (isSpace)
import Data.Maybe (maybeToList)
-- import Control.Arrow (second)
import Control.Functor.Pointed

data Words m = Chunk (Maybe m)
             | Segment (Maybe m) [m] (Maybe m)
    deriving (Show,Read)

runWords :: Words m -> [m]
runWords (Chunk m) = maybeToList m
runWords (Segment l m r) = maybeToList l ++ m ++ maybeToList r

instance Monoid m => Monoid (Words m) where
    mempty = Chunk mempty
    Chunk l `mappend` Chunk r = Chunk (l `mappend` r)
    Chunk l `mappend` Segment l' m r = Segment (l `mappend` l') m r
    Segment l m r `mappend` Chunk r' = Segment l m (r `mappend` r')
    Segment l m r `mappend` Segment l' m' r' = Segment l (m ++ maybeToList (r `mappend` l') ++ m') r'

instance Lexer Char m => Lexer Char (Words m) where
    lex c | isSpace c = Segment (Just (lex c)) [] mempty
          | otherwise = Chunk (Just (lex c))

instance Functor Words where
    fmap f (Chunk m) = Chunk (fmap f m)
    fmap f (Segment m ms m') = Segment (fmap f m) (fmap f ms) (fmap f m')

-- abuse the same machinery to handle lines as well

newtype Lines m = Lines (Words m) deriving (Show,Read,Monoid,Functor)

instance Lexer Char m => Lexer Char (Lines m) where
    lex '\n' = Lines $ Segment (Just (lex '\n')) [] mempty
    lex c = Lines $ Chunk (Just (lex c))

runLines :: Lines m -> [m]
runLines (Lines x) = runWords x

newtype Unspaced m = Unspaced { runUnspaced :: m }  deriving (Eq,Ord,Show,Read,Monoid)

instance Lexer Char m => Lexer Char (Unspaced m) where
    lex c | isSpace c = mempty
          | otherwise = Unspaced (lex c)

instance CharLexer m => CharLexer (Unspaced m) where
    invalid_char = Unspaced . invalid_char

instance Functor Unspaced where
    fmap f (Unspaced x) = Unspaced (f x)

instance Pointed Unspaced where
    point = Unspaced

instance Copointed Unspaced where
    extract = runUnspaced

newtype Unlined m = Unlined { runUnlined :: m }  deriving (Eq,Ord,Show,Read,Monoid)

instance Lexer Char m => Lexer Char (Unlined m) where
    lex '\n' = mempty
    lex c = Unlined (lex c)

instance CharLexer m => CharLexer (Unlined m) where
    invalid_char = Unlined . invalid_char

instance Functor Unlined where
    fmap f (Unlined x) = Unlined (f x)

instance Pointed Unlined where
    point = Unlined

instance Copointed Unlined where
    extract = runUnlined

-- accumulator, per-word, and up-until-next-word monoids
wordsFrom :: (Lexer Char m, Lexer Char n, Lexer Char o, Generator c (Words (m, Unspaced n, o))) => m -> c -> [(m,n,o)]
wordsFrom s c = [(x,y,z) | x <- scanl mappend s ls | y <- map runUnspaced ms | z <- rs ] where
    (ls,ms,rs) = unzip3 (runWords (lexMany c))

-- accumulator, per-line, and up-until-next-line monoids
linesFrom :: (Lexer Char m, Lexer Char n, Lexer Char o, Generator c (Lines (m, Unlined n, o))) => m -> c -> [(m,n,o)]
linesFrom s c = [(x,y,z) | x <- scanl mappend s ls | y <- map runUnlined ms | z <- rs] where
    (ls,ms,rs) = unzip3 (runLines (lexMany c))
