> {-# LANGUAGE OverloadedStrings, NoMonomorphismRestriction #-}

The purpose of this module is to extract Wikitext data from a MediaWiki XML
dump. This module won't parse the Wikitext itself; that's a job for
Text.Wiki.MediaWiki.

> module Text.MediaWiki.XML where
> import qualified Data.ByteString.Lazy as BSL
> import Data.ByteString (ByteString)
> import Data.Maybe

XML and text decoding:

> import Data.Text (Text)
> import qualified Data.Text as T
> import qualified Text.XML.Expat.SAX as SAX

The HTML processor that we'll run on the output:

> import Text.MediaWiki.HTML (extractWikiTextFromHTML)

Data types
==========

> data WikiPage = WikiPage {
>   pageNamespace :: Text,
>   pageTitle :: Text,
>   pageText :: Text,
>   pageRedirect :: Maybe Text
> } deriving (Show, Eq)

An AList is an association list, that type that shows up in functional
languages, where you map x to y by just putting together a bunch of (x,y)
tuples. Here, in particular, we're mapping text names to text values.

> type AList = [(Text, Text)]
>
> justLookup :: Text -> AList -> Text
> justLookup key aList = fromMaybe (error ("Missing tag: " ++ (T.unpack key))) (lookup key aList)

> makeWikiPage :: AList -> WikiPage
> makeWikiPage subtags = WikiPage {
>    pageNamespace = (justLookup "ns" subtags),
>    pageTitle = (justLookup "title" subtags),
>    pageText = extractWikiTextFromHTML (justLookup "text" subtags),
>    pageRedirect = lookup "redirect" subtags
> }

Top level
=========

> processMediaWikiDump :: String -> (WikiPage -> IO ()) -> IO ()
> processMediaWikiDump filename sink = do
>   contents <- BSL.readFile filename
>   let events = SAX.parse SAX.defaultParseOptions contents
>   mapM_ sink (findPageTags events)

Parsing some XML
================

> findPageTags = handleEventStream [] []

> handleEventStream :: AList -> [Text] -> [SAX.SAXEvent Text Text] -> [WikiPage]
> handleEventStream subtags chunks [] = []
> handleEventStream subtags chunks ((SAX.StartElement "page" attrs):rest) = handleEventStream [] [] rest
> handleEventStream subtags chunks ((SAX.StartElement "redirect" attrs):rest) =
>   let title = justLookup "title" attrs
>   in handleEventStream (("redirect",title):subtags) [] rest
> handleEventStream subtags chunks ((SAX.StartElement elt attrs):rest) = handleEventStream subtags [] rest
> handleEventStream subtags chunks ((SAX.EndElement "page"):rest) = ((makeWikiPage subtags):(handleEventStream [] [] rest))
> handleEventStream subtags chunks ((SAX.EndElement elt):rest) = handleEventStream ((elt, T.concat (reverse chunks)):subtags) [] rest
> handleEventStream subtags chunks ((SAX.CharacterData t):rest) = handleEventStream subtags (t:chunks) rest
