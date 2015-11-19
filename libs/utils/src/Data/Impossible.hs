{-# LANGUAGE PolyKinds #-}

module Data.Impossible where

import Prelude

impossible :: a
impossible = error "Impossible"

data Impossible = Impossible deriving (Show)

type ImpossibleM = ImpossibleM1
type ImpossibleT = ImpossibleM2

data ImpossibleM1 t1 = ImpossibleM1 deriving (Show)
data ImpossibleM2 t1 t2 = ImpossibleM2 deriving (Show)
data ImpossibleM3 t1 t2 t3 = ImpossibleM3 deriving (Show)
data ImpossibleM4 t1 t2 t3 t4 = ImpossibleM4 deriving (Show)
data ImpossibleM5 t1 t2 t3 t4 t5 = ImpossibleM5 deriving (Show)

