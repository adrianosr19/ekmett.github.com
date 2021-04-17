{-# LANGUAGE UndecidableInstances, TypeOperators, FlexibleContexts, MultiParamTypeClasses, FlexibleInstances #-}
module Data.Monoid.Lexical
    ( module Data.Monoid
    , Lexer
    , lex, affix, prefix
    , Generator
    , lexMany, affixMany, prefixMany
    , CharLexer
    , invalid_char
    , WithLexer(WithLexer, runWithLexer)
    , prelex
    , unlex
    ) where

import Prelude hiding (lex)
import Data.Monoid (Monoid, mempty, mappend)
import Data.Word (Word8)
import Data.Text (Text)
import Data.FingerTree
import Data.Foldable (fold,foldMap)
import qualified Data.Text as Text
import qualified Data.ByteString as Strict
import qualified Data.ByteString.Lazy as Lazy
import Control.Parallel.Strategies

-- minimal definition affix or lex
class Monoid m => c `Lexer` m where
    lex :: c -> m 
    affix :: m -> c -> m
    prefix :: c -> m -> m 

    lex = affix mempty 
    affix m c = m `mappend` lex c
    prefix c m = lex c `mappend` m

class Lexer Char m => CharLexer m where
    -- extra functionality used by the utf8-decoder monoid
    invalid_char :: [Word8] -> m
    invalid_char = const mempty

instance (Lexer c m, Lexer c m') => Lexer c (m,m') where
    lex x = (lex x,lex x)
    affix (m,m') x = (affix m x, affix m' x)
    prefix x (m,m') = (prefix x m, prefix x m')

instance (Lexer c m, Lexer c m', Lexer c m'') => Lexer c (m,m',m'') where
    lex x = (lex x,lex x, lex x)
    affix (m,m',m'') x = (affix m x, affix m' x, affix m'' x)
    prefix x (m,m',m'') = (prefix x m, prefix x m', prefix x m'')

instance (Lexer c m, Lexer c m', Lexer c m'', Lexer c m''') => Lexer c (m,m',m'',m''') where
    lex x = (lex x,lex x, lex x, lex x)
    affix (m,m',m'',m''') x = (affix m x, affix m' x, affix m'' x, affix m''' x)
    prefix x (m,m',m'',m''') = (prefix x m, prefix x m', prefix x m'', prefix x m''')

instance (CharLexer m, CharLexer m') =>  CharLexer (m,m') where
    invalid_char bs = (invalid_char bs, invalid_char bs)

instance (CharLexer m, CharLexer m', CharLexer m'') =>  CharLexer (m,m',m'') where
    invalid_char bs = (invalid_char bs, invalid_char bs, invalid_char bs)

instance (CharLexer m, CharLexer m', CharLexer m'', CharLexer m''') =>  CharLexer (m,m',m'',m''') where
    invalid_char bs = (invalid_char bs, invalid_char bs, invalid_char bs, invalid_char bs)

class Monoid m => Generator c m where
    lexMany :: c -> m
    affixMany :: m -> c -> m
    prefixMany :: c -> m -> m

    lexMany = affixMany mempty
    affixMany m c = m `mappend` lexMany c
    prefixMany c m = lexMany c `mappend` m 

instance Lexer Word8 m => Generator Strict.ByteString m where
    affixMany = Strict.foldl' affix

instance Lexer Word8 m => Generator Lazy.ByteString m where
    lexMany = fold . parMap rwhnf lexMany . Lazy.toChunks

instance Lexer Char m => Generator Text m where
    affixMany = Text.foldl' affix

instance Lexer c m => Generator [c] m where
    lexMany = foldMap lex

instance Measured v a => Generator (FingerTree v a) v where
    lexMany = measure
    affixMany m c = m `mappend` measure c
    prefixMany c m = measure c `mappend` m

snoc :: [a] -> a -> [a]
snoc xs x = xs ++ [x]

instance Lexer Char [Char] where
    lex = return
    prefix = (:)
    affix = snoc

instance CharLexer [Char]

instance Lexer Word8 [Word8] where
    lex = return
    prefix = (:)
    affix = snoc

newtype c `WithLexer` m = WithLexer { runWithLexer :: (m,c) } 

prelex :: (c `Lexer` m) => c -> c `WithLexer` m
prelex x = d `seq` WithLexer (d, x) where d = lex x

unlex :: c `WithLexer` m -> c
unlex = snd . runWithLexer

instance Lexer c m => Lexer (c `WithLexer` m) m where
    lex = fst . runWithLexer 

-- for finger tree compatibility
instance Lexer c m => Measured m (c `WithLexer` m) where
    measure = fst . runWithLexer

-- instance Measured v a => Lexer v (FingerTree v a) where
--     lex = measure
