{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE PolyKinds #-} -- Used by proxy DataType declaration


module FlowboxM.Luna.Helpers.Core (
    module Prelude,
	module FlowboxM.Luna.Helpers.Core,
    module FlowboxM.Luna.Helpers.TH.Inst,
    module FlowboxM.Luna.Helpers.StdLib,
    module FlowboxM.Luna.Helpers.Imports,
    OneTuple(..)
)
where

import           Prelude hiding((>>), (>>=), fail, return)
import qualified Prelude as Prelude
import           FlowboxM.Luna.Helpers.TH.Inst       
import           FlowboxM.Luna.Helpers.StdLib        
import           Control.Applicative
import           Data.Tuple.OneTuple
import           GHC.Generics                      (Generic)

import           FlowboxM.Utils.Generics.Show
import           FlowboxM.Luna.Helpers.Imports

import GHC.TypeLits            

(.:) :: (c -> d) -> (a -> b -> c) -> (a -> b -> d)
-- f .: g = \x y->f (g x y)
-- f .: g = (f .) . g
-- (.:) f = ((f .) .)
-- (.:) = (.) (.) (.)
(.:) = (.) . (.)


class Failure (a :: Symbol)

class Get0 m f |  m -> f where
    get0 :: m -> f

class Get1 m f |  m -> f where
    get1 :: m -> f

class Get2 m f |  m -> f where
    get2 :: m -> f

class Get3 m f |  m -> f where
    get3 :: m -> f


instance Get0 (Pure Int) (Pure Int) where
    get0 = id

instance Get0 (Pure [a]) (Pure [a]) where
    get0 = id


instance Get0 (Pure ()) (Pure ()) where get0 = id
instance Get0 (Pure (OneTuple a)) (Pure (OneTuple a)) where get0 = id
instance Get0 (Pure (v1,v2)) (Pure (v1,v2)) where get0 = id
instance Get0 (Pure (v1,v2,v3)) (Pure (v1,v2,v3)) where get0 = id
instance Get0 (Pure (v1,v2,v3,v4)) (Pure (v1,v2,v3,v4)) where get0 = id
instance Get0 (Pure (v1,v2,v3,v4,v5)) (Pure (v1,v2,v3,v4,v5)) where get0 = id


mkPure0  a = Pure $ a
mkPure1  a v1 = Pure $ a v1
mkPure2  a v1 v2 = Pure $ a v1 v2
mkPure3  a v1 v2 v3 = Pure $ a v1 v2 v3
mkPure4  a v1 v2 v3 v4 = Pure $ a v1 v2 v3 v4
mkPure5  a v1 v2 v3 v4 v5 = Pure $ a v1 v2 v3 v4 v5
mkPure6  a v1 v2 v3 v4 v5 v6 = Pure $ a v1 v2 v3 v4 v5 v6
mkPure7  a v1 v2 v3 v4 v5 v6 v7 = Pure $ a v1 v2 v3 v4 v5 v6 v7
mkPure8  a v1 v2 v3 v4 v5 v6 v7 v8 = Pure $ a v1 v2 v3 v4 v5 v6 v7 v8
mkPure9  a v1 v2 v3 v4 v5 v6 v7 v8 v9 = Pure $ a v1 v2 v3 v4 v5 v6 v7 v8 v9
mkPure10 a v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 = Pure $ a v1 v2 v3 v4 v5 v6 v7 v8 v9 v10



pureIO :: a -> IO a
pureIO = Prelude.return

failIO :: String -> IO a
failIO = Prelude.fail


tuple2 a b = (,) <$> a <*> b

(>>=) = bind
(>>)  = bind_
fail  = failIO
return a = a


defFunction0 f = f

defFunction1 f v1 = do
    v1' <- getIO v1
    f (Pure v1')

defFunction2 f v1 v2 = do
    v1' <- getIO v1
    v2' <- getIO v2
    f (Pure v1') (Pure v2')

defFunction3 f v1 v2 v3 = do
    v1' <- getIO v1
    v2' <- getIO v2
    v3' <- getIO v3
    f (Pure v1') (Pure v2') (Pure v3')

defFunction4 f v1 v2 v3 v4 = do
    v1' <- getIO v1
    v2' <- getIO v2
    v3' <- getIO v3
    v4' <- getIO v4
    f (Pure v1') (Pure v2') (Pure v3') (Pure v4')

defFunction5 f v1 v2 v3 v4 v5 = do
    v1' <- getIO v1
    v2' <- getIO v2
    v3' <- getIO v3
    v4' <- getIO v4
    v5' <- getIO v5
    f (Pure v1') (Pure v2') (Pure v3') (Pure v4') (Pure v5')



liftFPure1  f (Pure a) = Pure $ f a
liftFPure2  f (Pure a) = liftFPure1 (f a)
liftFPure3  f (Pure a) = liftFPure2 (f a)
liftFPure4  f (Pure a) = liftFPure3 (f a)
liftFPure5  f (Pure a) = liftFPure4 (f a)
liftFPure6  f (Pure a) = liftFPure5 (f a)
liftFPure7  f (Pure a) = liftFPure6 (f a)
liftFPure8  f (Pure a) = liftFPure7 (f a)
liftFPure9  f (Pure a) = liftFPure8 (f a)
liftFPure10 f (Pure a) = liftFPure9 (f a)


liftFIO1  f (Pure a) = f a
liftFIO2  f (Pure a) = liftFIO1 (f a)
liftFIO3  f (Pure a) = liftFIO2 (f a)
liftFIO4  f (Pure a) = liftFIO3 (f a)
liftFIO5  f (Pure a) = liftFIO4 (f a)
liftFIO6  f (Pure a) = liftFIO5 (f a)
liftFIO7  f (Pure a) = liftFIO6 (f a)
liftFIO8  f (Pure a) = liftFIO7 (f a)
liftFIO9  f (Pure a) = liftFIO8 (f a)
liftFIO10 f (Pure a) = liftFIO9 (f a)


concatPure a                  = concat $ map getPure a
rangeFromTo (Pure a) (Pure b) = Pure $ map Pure $ if a < b then [a..b] else [a,a-1..b]
rangeFrom   (Pure a)          = Pure $ map Pure $ [a..]



class Member (name :: Symbol) cls func | name cls -> func where 
    member :: proxy name -> cls -> func


data Proxy a = Proxy
