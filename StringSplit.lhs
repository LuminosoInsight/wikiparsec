Some string-splitting functions that help us parse links without backtracking:

> module StringSplit (splitFirst, splitLast) where

{\tt splitFirst} finds the first occurrence of a separator character, and
splits the string at that point, returning the text before and after the
separator. If the separator never appears, the suffix will be the empty string.

> splitFirst :: (Eq a) => a -> [a] -> ([a], [a])
> splitFirst char [] = ([], [])
> splitFirst char (next:rest) =
>   if char == next
>   then ([], rest)
>   else let (before, after) = splitFirst char rest
>         in (next:before, after)

{\tt splitLast} finds the {\em last} occurrence of a separator character
and splits the string at that point. This is easiest to define as a reversal
of {\tt splitFirst}.

> splitLast :: (Eq a) => a -> [a] -> ([a], [a])
> splitLast char str =
>   let (beforeR, afterR) = splitFirst char (reverse str) in
>     (reverse afterR, reverse beforeR)
