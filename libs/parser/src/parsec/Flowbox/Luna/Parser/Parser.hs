---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE NoMonomorphismRestriction, FlexibleInstances, ScopedTypeVariables, TupleSections #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

module Flowbox.Luna.Parser.Parser where

import Control.Applicative
import Data.Char (isSpace)
import Data.Either.Utils (forceEither)
import Data.Monoid
import System.Environment (getArgs)
import Text.Parsec hiding (parse, many, optional, (<|>))
import qualified Text.Parsec as Parsec
import Data.List ( nub, sort )
import Data.Char ( isAlpha, toLower, toUpper, isSpace, digitToInt )
import qualified Text.Parsec.Expr as Expr
import Text.Parsec.Indent

import qualified Flowbox.Luna.Parser.Lexer   as L
import qualified Flowbox.Luna.Parser.AST.AST as AST

import qualified Text.Show.Pretty as PP
import System.TimeIt
import Debug.Trace
import Flowbox.Luna.Parser.AST.AST -- for tests


parens p        = between (L.symbol "(") (L.symbol ")") p

---------- Entities ----------

pIdent      = AST.Identifier   <$> L.identifier


----------------------

expr    = Expr.buildExpressionParser table term
      <?> "expression"

term    =  parens expr 
       <|> pIdent
       <|> pFunc
       -- <|> L.natural
      <?> "simple expression"

table   = [ 
            --[prefix "-" negate, prefix "+" id ]
          --, [postfix "++" (+1)]
          --, [binary "*" (*) Expr.AssocLeft, binary "/" (div) Expr.AssocLeft ]
          --, [binary "+" (+) Expr.AssocLeft, binary "-" (-)   Expr.AssocLeft ]
            [binary "+"  (AST.Operator "+")  Expr.AssocLeft]
          , [binary ""   AST.callConstructor Expr.AssocLeft]
          , [binary "="  AST.Assignment      Expr.AssocLeft]
          ]
      
binary  name fun assoc = Expr.Infix   (L.reservedOp name *> return fun) assoc
prefix  name fun       = Expr.Prefix  (L.reservedOp name *> return fun)
postfix name fun       = Expr.Postfix (L.reservedOp name *> return fun)


pFunc         = AST.Function <$  L.pDef 
                               <*> L.identifier 
                               <*  L.pBlockBegin
                               <*  L.eol
                               <*>  pSegmentBegin expr 1
                               -- <*  L.eol
                               -- <*  L.eol  <* L.simpleSpace
                               -- <*  L.eol
                             -- <*> (pTuplePure (pOpExpr2 i) <<|> pTupleBody (pOpExpr2 i))
                             -- <*> pExprBlock i

pEmptyLines         = many1 pEmptyLine
pEmptyLine          = try(L.eol *> L.spaces *> L.eol) <|> L.eol

pCountAtLast    i p = (++) <$> count i p <*> many p

pIndentExact      i = i <$ count i (char ' ')
pIdentAtLast      i = length <$> pCountAtLast i (char ' ')

pSegments       p i = many $ try $ (pEmptyLines *> pSegment p i)

pSegmentBegin   p i = do
    j <- many pEmptyLines *> pIdentAtLast i
    (:) <$> p <*> pSegments p j

pSegment        p i = try (id <$ pIndentExact i <*> p)


example = unlines [ ""
                  --, "def f:\n\n\n\n"
                  --, "  a b"
                  --, "  c"
                  --, "def d:"
                  --, "    d"
				  ]

pProgram = option [] $ pSegmentBegin expr 0 


--parse input = runIndent "Luna Parser" $ runParserT pProgram () "" input
parse input = Parsec.parse pProgram "Luna Parser" input




tests = [
          ("Empty input",    [""]                  , [])  
        , ("Empty function", ["def f:"]         , []) 
        --, ("Simple function","def f(x=0):x"     , [Function {name = "f", signature = [Assignment (Identifier "x") (Constant (Integer "0"))], body = [Identifier "x"]}]) 
        --, ("Multiline function",
        --      "def f(x):\
        --    \\n    x()\
        --    \\n    y()\
        --    \\n"
        --                                        , [Function {name = "f", signature = [Identifier "x"], body = [Call {src = Identifier "x", args = []},Call {src = Identifier "y", args = []}]}]) 
        --, ("Multiple simple functions",
        --      "def f(x):x\
        --    \\ndef g(y):y"
        --                                        , [Function {name = "f", signature = [Identifier "x"], body = [Identifier "x"]},Function {name = "g", signature = [Identifier "y"], body = [Identifier "y"]}]) 
        --, ("Empty class", "class A:"            , [Class {name = "A", params = [], body = []}]) 
        --, ("Simple class",
        --      "class A:\
        --    \\n    i::Int"
        --                                        , [Class {name = "A", params = [], body = [Typed "Int" (Identifier "i")]}]) 
        --, ("Class with a function",
        --      "class A:\
        --    \\n    def f(x):\
        --    \\n        x"
        --                                        , [Class {name = "A", params = [], body = [Function {name = "f", signature = [Identifier "x"], body = [Identifier "x"]}]}]) 
        --, ("Testing emptylines 1",
        --      "class A:\
        --    \\n \
        --    \\n\
        --    \\n    def f(x):\
        --    \\n \
        --    \\n\
        --    \\n        x\n"
        --                                        , [Class {name = "A", params = [], body = [Function {name = "f", signature = [Identifier "x"], body = [Identifier "x"]}]}]) 
        --, ("Simple function call", "f(x,y,z)"   , [Call {src = Identifier "f", args = [Identifier "x",Identifier "y",Identifier "z"]}]) 
        --, ("Simple operators", "a+b"            , [Operator {name = "+", srd = Identifier "a", dst = Identifier "b"}]) 
        --, ("test", "f"                          , [Identifier "f"]) 
        --, ("test", "g h"                        , [Call {src = Identifier "g", args = [Identifier "h"]}]) 
        --, ("test", "g h()"                      , [Call {src = Identifier "g", args = [Call {src = Identifier "h", args = []}]}]) 
        --, ("test", "g h ()"                     , [Call {src = Identifier "g", args = [Identifier "h",Tuple {items = []}]}]) 
        --, ("test", "g(h,i)"                     , [Call {src = Identifier "g", args = [Identifier "h",Identifier "i"]}]) 
        --, ("test", "g h i"                      , [Call {src = Identifier "g", args = [Identifier "h",Identifier "i"]}]) 
        --, ("test", "g + 1"                      , [Operator {name = "+", srd = Identifier "g", dst = Constant (Integer "1")}]) 
        --, ("test", "g(x) h"                     , [Call {src = Call {src = Identifier "g", args = [Identifier "x"]}, args = [Identifier "h"]}]) 
        --, ("test", "g x h"                      , [Call {src = Identifier "g", args = [Identifier "x",Identifier "h"]}]) 

        --, ("Class with a function",
        --      "class Vector a:\
        --    \\n    x :: a     \
        --    \\n    y :: a     \
        --    \\n    z :: a     \
        --    \\n    def length(self):  \
        --    \\n        self.x^2 + self.y^2 + self.z^2\n"
        --                                        , [Class {name = "Vector", params = ["a"], body = [Typed "a" (Identifier "x"),Typed "a" (Identifier "y"),Typed "a" (Identifier "z"),Function {name = "length", signature = [Identifier "self"], body = [Operator {name = "+", srd = Operator {name = "+", srd = Operator {name = "^", srd = Accessor {src = Identifier "self", dst = Identifier "x"}, dst = Constant (Integer "2")}, dst = Operator {name = "^", srd = Accessor {src = Identifier "self", dst = Identifier "y"}, dst = Constant (Integer "2")}}, dst = Operator {name = "^", srd = Accessor {src = Identifier "self", dst = Identifier "z"}, dst = Constant (Integer "2")}}]}]}]) 

        ----, ("Simple lambda", "x:x+1")
        ----, ("Double lambda", "x: y:x+y")

        --, ("Exception catch", "a.catch e:         \
        --                    \\n    print 1        \
        --                    \\n    print e.message"
        --                                        , [Call {src = Accessor {src = Identifier "a", dst = Identifier "catch"}, args = [Lambda {signature = [Identifier "e"], body = [Call {src = Identifier "print", args = [Constant (Integer "1")]},Call {src = Identifier "print", args = [Accessor {src = Identifier "e", dst = Identifier "message"}]}]}]}]) 
        --, ("Simple Char literals", "'a'"        , [Constant (Char 'a')])
        --, ("Simple string literals", "\"ala\""  , [Constant (String "ala")])
        --, ("Simple import", "import Std.Math.Vector as Vector", [Import {paths = [Named {name = "Vector", item = Path {segments = ["Std","Math","Vector"]}}]}])
        --, ("Simple from import", "from Std.Math import Vector", [ImportQualified {path = Path {segments = ["Std","Math"]}, imports = Import {paths = [Path {segments = ["Vector"]}]}}])
        --, ("Complex import", 
        --   "import Std.Math.Vector as Vector\
        -- \\n       Std.Math.Scalar as Scalar"
        --                                        ,[Import {paths = [Named {name = "Vector", item = Path {segments = ["Std","Math","Vector"]}},Named {name = "Scalar", item = Path {segments = ["Std","Math","Scalar"]}}]}])
        --, ("Complex from import", 
        --   "from Std.Math import Vector\
        -- \\n                     Scalar"        
        --                                        ,[ImportQualified {path = Path {segments = ["Std","Math"]}, imports = Import {paths = [Path {segments = ["Vector"]},Path {segments = ["Scalar"]}]}}]
        --  )
        --, ("Exception catch", "e:         \
        --                    \\n    a\n", [])
        ----, ("test", "a=b;b=c", []) -- currently unimplemented
        --("Simple comment", "a=b #[c         \
        --                 \\ndalej komentarz \
        --                 \\n#[nested comment\
        --                 \\n#]xx            \
        --                 \\n#]", [])
        --("Simple comment2", "###################", [])

        --("Empty input",    "x: y: x+y"                  , [])  
        --,("Empty input",    "a b"                  , [])  
        --,("Empty input",    "a+b"                  , [])  
        ]


main = do
    timeIt main_inner

main_inner = do
    --args <- getArgs
    --input <- if null args then return example else readFile $ head args
    --putStrLn $ PP.ppShow $ parse example
    mapM_ (run True) tests
    return ()
    --putStrLn $ serializeIndentedTree $ forceEither $ parseIndentedTree input



run force (title, inp, exp) = 
    do 
        putStr ("=== " ++ title ++ " ===" ++ replicate (30 - length title) ' ')
        let a =  parse $ unlines inp
        case a of
            Right expr -> do 
                if (expr == exp)
                    then putStrLn "ok."
                    else putStrLn $ "FAIL (wrong result)"
                
                if (expr /= exp) || force
                    then do
                        print_err a
                        putStrLn $ PP.ppShow a
                    else return ()
            Left  e   -> do
                putStrLn $ "FAIL (parse fail)"
                print_err a

    where
        print_err a = do
            print a
            putStrLn ""
                            
                            
