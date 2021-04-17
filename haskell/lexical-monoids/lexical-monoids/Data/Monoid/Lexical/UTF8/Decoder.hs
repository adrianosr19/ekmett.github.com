{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses #-}
module Data.Monoid.Lexical.UTF8.Decoder 
    ( UTF8
    , runUTF8
    ) where
    
import Prelude hiding (lex)

import Data.Bits (shiftL,(.&.),(.|.))
import Data.Word (Word8)

import Control.Functor.Pointed

import Data.Monoid.Lexical

char :: CharLexer m => Char -> m
char = lex

-- Incrementally lex canonical RFC3629 UTF-8 Characters

-- utf8 characters are at most 4 characters long, so we need only retain state for 3 of them
-- moreover their length is able to be determined a priori, so lets store that intrinsically in the constructor
data H = H0
       | H2_1 !Word8 
       | H3_1 !Word8
       | H3_2 !Word8 !Word8
       | H4_1 !Word8
       | H4_2 !Word8 !Word8
       | H4_3 !Word8 !Word8 !Word8

-- words expressing the tail of a character, each between 0x80 and 0xbf
-- this is arbitrary length to simplify making the parser truly monoidal
-- this probably means we have O(n^2) worst case performance in the face of very long runs of chars that look like 10xxxxxx
type T = [Word8]

-- S is a segment that contains a possible tail of a character, the result of lexing some full characters, and the start of another character
-- T contains a list of bytes each between 0x80 and 0xbf
data UTF8 m = S T m !H
            | T T

-- flush any extra characters in a head, when the next character isn't between 0x80 and 0xbf
flushH :: CharLexer m => H -> m
flushH (H0) = mempty
flushH (H2_1 x) = invalid_char [x]
flushH (H3_1 x) = invalid_char [x]
flushH (H3_2 x y) = invalid_char [x,y]
flushH (H4_1 x) = invalid_char [x]
flushH (H4_2 x y) = invalid_char [x,y]
flushH (H4_3 x y z) = invalid_char [x,y,z]

-- flush a character tail 
flushT :: CharLexer m => [Word8] -> m
flushT = invalid_char

affixH :: CharLexer m => H -> Word8 -> (m -> H -> UTF8 m) -> m -> UTF8 m
affixH H0 c k m 
    | c < 0x80 = k (m `mappend` b1 c) H0
    | c < 0xc0 = k (m `mappend` invalid_char [c]) H0
    | c < 0xe0 = k m (H2_1 c)
    | c < 0xf0 = k m (H3_1 c)
    | c < 0xf5 = k m (H4_1 c)
    | otherwise = k (m `mappend` invalid_char [c]) H0
affixH (H2_1 c) d k m
    | d >= 0x80 && d < 0xc0 = k (m `mappend` b2 c d) H0
    | otherwise = k (m `mappend` invalid_char [c]) H0
affixH (H3_1 c) d k m 
    | d >= 0x80 && d < 0xc0 = k m (H3_2 c d)
    | otherwise = k (m `mappend` invalid_char [c]) H0
affixH (H3_2 c d) e k m 
    | d >= 0x80 && d < 0xc0 = k (m `mappend` b3 c d e) H0
    | otherwise = k (m `mappend` invalid_char [c,d]) H0
affixH (H4_1 c) d k m 
    | d >= 0x80 && d < 0xc0 = k m (H4_2 c d)
    | otherwise = k (m `mappend` invalid_char [c,d]) H0
affixH (H4_2 c d) e k m 
    | d >= 0x80 && d < 0xc0 = k m (H4_3 c d e)
    | otherwise = k (m `mappend` invalid_char [c,d,e]) H0
affixH (H4_3 c d e) f k m 
    | d >= 0x80 && d < 0xc0 = k (m `mappend` b4 c d e f) H0
    | otherwise = k (m `mappend` invalid_char [c,d,e,f]) H0

mask :: Word8 -> Word8 -> Int
mask c m = fromEnum (c .&. m) 

combine :: Int -> Word8 -> Int
combine a r = shiftL a 6 .|. fromEnum (r .&. 0x3f)

b1 :: CharLexer m => Word8 -> m
b1 c | c < 0x80 = char . toEnum $ fromEnum c
     | otherwise = invalid_char [c]

b2 :: CharLexer m => Word8 -> Word8 -> m
b2 c d | valid_b2 c d = char (toEnum (combine (mask c 0x1f) d))
       | otherwise = invalid_char [c,d]

b3 :: CharLexer m => Word8 -> Word8 -> Word8 -> m
b3 c d e | valid_b3 c d e = char (toEnum (combine (combine (mask c 0x0f) d) e))
         | otherwise = invalid_char [c,d,e]


b4 :: CharLexer m => Word8 -> Word8 -> Word8 -> Word8 -> m
b4 c d e f | valid_b4 c d e f = char (toEnum (combine (combine (combine (mask c 0x07) d) e) f))
           | otherwise = invalid_char [c,d,e,f]

valid_b2 :: Word8 -> Word8 -> Bool
valid_b2 c d = (c >= 0xc2 && c <= 0xdf && d >= 0x80 && d <= 0xbf)

valid_b3 :: Word8 -> Word8 -> Word8 -> Bool
valid_b3 c d e = (c == 0xe0 && d >= 0xa0 && d <= 0xbf && e >= 0x80 && e <= 0xbf) || 
                 (c >= 0xe1 && c <= 0xef && d >= 0x80 && d <= 0xbf && e >= 0x80 && e <= 0xbf)

valid_b4 :: Word8 -> Word8 -> Word8 -> Word8 -> Bool
valid_b4 c d e f = (c == 0xf0 && d >= 0x90 && d <= 0xbf && e >= 0x80 && e <= 0xbf && f >= 0x80 && f <= 0xbf) ||
      (c >= 0xf1 && c <= 0xf3 && d >= 0x80 && d <= 0xbf && e >= 0x80 && e <= 0xbf && f >= 0x80 && f <= 0xbf) ||
                   (c == 0xf4 && d >= 0x80 && d <= 0x8f && e >= 0x80 && e <= 0xbf && f >= 0x80 && f <= 0xbf)

prefixT :: CharLexer m => Word8 -> T -> (H -> UTF8 m) -> (m -> UTF8 m) -> (T -> UTF8 m) -> UTF8 m
prefixT c cs h m t
             | c < 0x80 = m $ b1 c `mappend` invalid_chars cs
             | c < 0xc0 = t (c:cs)
             | c < 0xe0 = case cs of
                        [] -> h $ H2_1 c
                        (d:ds) -> m $ b2 c d `mappend` invalid_chars ds
             | c < 0xf0 = case cs of
                        [] -> h $ H3_1 c
                        [d] -> h $ H3_2 c d
                        (d:e:es) -> m $ b3 c d e `mappend` invalid_chars es
             | c < 0xf5 = case cs of
                        [] -> h $ H4_1 c
                        [d] -> h $ H4_2 c d 
                        [d,e] -> h $ H4_3 c d e 
                        (d:e:f:fs) -> m $ b4 c d e f `mappend` invalid_chars fs
             | otherwise = mempty

invalid_chars :: CharLexer m => [Word8] -> m
invalid_chars (x:xs) = invalid_char [x] `mappend` invalid_chars xs
invalid_chars [] = mempty

merge :: CharLexer m => H -> T -> (m -> a) -> (H -> a) -> a
merge H0 cs k _               = k $ invalid_chars cs
merge (H2_1 c) [] _ p         = p $ H2_1 c
merge (H2_1 c) (d:ds) k _     = k $ b2 c d `mappend` invalid_chars ds
merge (H3_1 c) [] _ p         = p $ H3_1 c
merge (H3_1 c) [d] _ p        = p $ H3_2 c d
merge (H3_1 c) (d:e:es) k _   = k $ b3 c d e `mappend` invalid_chars es
merge (H3_2 c d) [] _ p       = p $ H3_2 c d
merge (H3_2 c d) (e:es) k _   = k $ b3 c d e `mappend` invalid_chars es
merge (H4_1 c) [] _ p         = p $ H4_1 c
merge (H4_1 c) [d] _ p        = p $ H4_2 c d
merge (H4_1 c) [d,e] _ p      = p $ H4_3 c d e
merge (H4_1 c) (d:e:f:fs) k _ = k $ b4 c d e f `mappend` invalid_chars fs
merge (H4_2 c d) [] _ p       = p $ H4_2 c d 
merge (H4_2 c d) [e] _ p      = p $ H4_3 c d e
merge (H4_2 c d) (e:f:fs) k _ = k $ b4 c d e f `mappend` invalid_chars fs
merge (H4_3 c d e) [] _ p     = p $ H4_3 c d e
merge (H4_3 c d e) (f:fs) k _ = k $ b4 c d e f `mappend` invalid_chars fs

instance CharLexer m => Monoid (UTF8 m) where
    mempty = T []
    T c `mappend` T d = T (c ++ d)
    T c `mappend` S l m r = S (c ++ l) m r
    S l m c `mappend` S c' m' r = S l (m `mappend` merge c c' id flushH `mappend` m') r
    s@(S _ _ _) `mappend` T [] = s
    S l m c `mappend` T c' = merge c c' k (S l m) where
        k m' = S l (m `mappend` m') H0

instance CharLexer m => Lexer Word8 (UTF8 m) where
    prefix c (T cs) = prefixT c cs (S [] mempty) (flip (S []) H0) T
    prefix c (S cs m h) = prefixT c cs 
        (\h' -> S [] (flushH h' `mappend` m) h)
        (\m' -> S [] (m' `mappend` m) h)
        (\t' -> S t' m h)
    affix (S t m h) c = affixH h c (S t) m
    affix (T t) c | c >= 0x80 && c < 0xc0 = T (t ++ [c])
                  | otherwise = affixH H0 c (S t) mempty
    
instance Functor UTF8 where
    fmap f (S t x h) = S t (f x) h
    fmap _ (T t) = T t

instance Pointed UTF8 where
    point f = S [] f H0

runUTF8 :: CharLexer m => UTF8 m -> m 
runUTF8 (T t) = flushT t
runUTF8 (S t m h) = flushT t `mappend` m `mappend` flushH h
