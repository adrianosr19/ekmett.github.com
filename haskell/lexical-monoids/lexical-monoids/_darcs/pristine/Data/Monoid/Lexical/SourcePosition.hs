{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}
module Data.Monoid.Lexical.SourcePosition
    ( SourcePosition
    , SourceLine
    , SourceColumn
    , sourceLine
    , sourceColumn
    , startOfFile
    , showSourcePosition
    ) where

import Prelude hiding (lex)
import Control.Functor.Extras
import Control.Functor.Pointed
import Data.Monoid.Lexical

type SourceLine = Int
type SourceColumn = Int

data SourcePosition file = Pos file {-# UNPACK #-} !SourceLine !SourceColumn
         | Lines {-# UNPACK #-} !SourceLine !SourceColumn
         | Columns {-# UNPACK #-} !SourceColumn
         | Tab {-# UNPACK #-} !SourceColumn !SourceColumn -- cols before and after an unresolved tab
    deriving (Read,Show,Eq)

nextTab :: Int -> Int
nextTab x = x + (8 - (x-1) `mod` 8)

instance Functor SourcePosition where
    fmap g (Pos f l c) = Pos (g f) l c
    fmap _ (Lines l c) = Lines l c
    fmap _ (Columns c) = Columns c
    fmap _ (Tab x y) = Tab x y

instance Pointed SourcePosition where
    point f = Pos f 1 1

instance FunctorZero SourcePosition where
    fzero = mempty

instance FunctorPlus SourcePosition where
    fplus = mappend

instance Monoid (SourcePosition file) where
    mempty = Columns 0

    Pos f l _ `mappend` Lines m d = Pos f (l + m) d
    Pos f l c `mappend` Columns d = Pos f l (c + d)
    Pos f l c `mappend` Tab x y   = Pos f l (nextTab (c + x) + y)
    Lines l _ `mappend` Lines m d = Lines (l + m) d
    Lines l c `mappend` Columns d = Lines l (c + d)
    Lines l c `mappend` Tab x y   = Lines l (nextTab (c + x) + y)
    Columns c `mappend` Columns d  = Columns (c + d)
    Columns c `mappend` Tab x y    = Tab (c + x) y
    Tab _ _   `mappend` Lines m d  = Lines m d
    Tab x y   `mappend` Columns d  = Tab x (y + d)
    Tab x y   `mappend` Tab x' y'  = Tab x (nextTab (y + x') + y')
    _         `mappend` pos        = pos

instance Lexer Char (SourcePosition file) where
    lex '\n' = Lines 1 0
    lex '\t' = Tab 0 0 
    lex _    = Columns 1

instance CharLexer (SourcePosition file)
    
startOfFile :: f -> SourcePosition f
startOfFile = point

sourceColumn :: SourcePosition f -> Maybe SourceColumn
sourceColumn (Pos _ _ c) = Just c
sourceColumn (Lines _ c) = Just c
sourceColumn _ = Nothing

sourceLine :: SourcePosition f -> Maybe SourceLine
sourceLine (Pos _ l _) = Just l
sourceLine _ = Nothing

showSourcePosition :: SourcePosition String -> String
showSourcePosition pos = showSourcePosition' (point "-" `mappend` pos) where
    showSourcePosition' (Pos f l c) = f ++ ":" ++ show l ++ ":" ++ show c
    showSourcePosition' _ = undefined
