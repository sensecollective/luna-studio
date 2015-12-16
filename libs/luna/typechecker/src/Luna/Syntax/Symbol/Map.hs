{-# LANGUAGE KindSignatures       #-}
{-# LANGUAGE TypeFamilies         #-}
{-# LANGUAGE UndecidableInstances #-}

module Luna.Syntax.Symbol.Map where

import Prologue

import           Control.Error.Operator
import           Control.Monad.Extra         (allM, findM)
import qualified Data.List                   as List
import           Data.Map                    (Map)
import qualified Data.Map                    as Map
import           Luna.Syntax.AST.Arg         (NamedArg (NamedArg))
import           Luna.Syntax.AST.Arg         (Arg (Arg))
import           Luna.Syntax.AST.Term        (Arrow (Arrow))
import           Luna.Syntax.Builder         (RefReader, readRef)
import           Luna.Syntax.Builder.Class   (BuilderMonad)
import qualified Luna.Syntax.Builder.Symbol  as SymbolBuilder
import           Luna.Syntax.Name
import           Luna.Syntax.Repr.Graph      (Ref)
import           Luna.Syntax.Symbol.Network  (Network)
import           Luna.Syntax.Symbol.QualPath (QualPath)



type GeneralizedNetwork = Network
type SpecializedNetwork = Network


data SymbolError = CouldNotSpecialize { errMsg :: String }
                 | SymbolNotFound     { qpath :: QualPath }
                 deriving (Show)

data ArgLstType = Specified
                | Specialized
                deriving (Show)

type family ArgList t a where ArgList 'Specified a = Map Name a
                              ArgList 'Specialized a = [NamedArg a]

type family Result t a where Result 'Specified   a = Maybe a
                             Result 'Specialized a = a

data Args (x :: ArgLstType) t = Args
    { _positional :: [t]
    , _named      :: ArgList x t
    }

makeLenses ''Args

deriving instance (Show (ArgList x t), Show         t)  => Show (Args x t)
deriving instance (Eq   (ArgList x t), Eq           t)  => Eq   (Args x t)
deriving instance (Ord  (ArgList x t), Ord          t)  => Ord  (Args x t)
deriving instance (Show (Result  x t), Show (Args x t)) => Show (Signature x t)
deriving instance (Ord  (Result  x t), Ord  (Args x t)) => Ord  (Signature x t)
deriving instance (Eq   (Result  x t), Eq   (Args x t)) => Eq   (Signature x t)

type Specification t = Signature 'Specified t
type Specialization t = Signature 'Specialized t

data Signature (x :: ArgLstType) t = Signature
    { _args   :: Args x t
    , _result :: Result x t
    }
makeLenses ''Signature

type SpecializationMap t = Map (Specialization t) SpecializedNetwork

data PartiallySpecializedNetwork t = PartiallySpecializedNetwork
    { _general :: GeneralizedNetwork
    , _specs   :: SpecializationMap t
    } -- deriving (Show)

makeLenses ''PartiallySpecializedNetwork

type SymbolMap t = Map QualPath (PartiallySpecializedNetwork t)

type SymbolMonad t = SymbolBuilder.MonadSymbolBuilder (SymbolMap t)


fromArrow :: Arrow t -> Specification t
fromArrow (Arrow p n r) = Signature (Args p n) (Just r)
-- fromArrow :: Arrow t -> Signature Specified t

fromArrow' :: Arrow t -> Specialization t
fromArrow' (Arrow p n r) = Signature (Args p $ map mkArg $ Map.toList n) r
    where mkArg (k, v)= NamedArg k v


toArrow :: Signature 'Specialized t -> Arrow t
toArrow (Signature (Args p n) r) = Arrow p (Map.fromList $ map fromNamed n) r
    where fromNamed (NamedArg k v) = (k, v)


symbolLookup :: SymbolMonad t m => QualPath -> m (Maybe (PartiallySpecializedNetwork t))
symbolLookup qpath' = Map.lookup qpath' <$> SymbolBuilder.get

graph :: SymbolMonad t m => QualPath ->  m (Maybe GeneralizedNetwork)
graph qpath' = fmap (view general) <$> symbolLookup qpath'

specializations :: SymbolMonad t m => QualPath -> m (Maybe (SpecializationMap t))
specializations qpath' = fmap (view specs) <$> symbolLookup qpath'

getSpecialization :: (SymbolMonad (Ref t) m, Ord t, RefReader t (ExceptT Bool (ExceptT SymbolError m)) t0)
                  => QualPath -> Specification (Ref t) -> ExceptT SymbolError m (Specialization (Ref t), SpecializedNetwork)
getSpecialization qpath' specif = SymbolBuilder.modifyM $ \symbolMap -> do
    part <- Map.lookup qpath' symbolMap <??> SymbolNotFound qpath'
    findM (specificationMatch specif . fst) (Map.toList $ part ^. specs) >>= \case
        Just specializedNetwork -> return (symbolMap, specializedNetwork)
        Nothing -> do
            r@(newSpecialization, newNetwork) <- makeSpecialization specif $ part ^. general
            return (Map.adjust (specs %~ Map.insert newSpecialization newNetwork) qpath' symbolMap, r)

makeSpecialization :: SymbolMonad t m => Specification t -> GeneralizedNetwork
                   -> ExceptT SymbolError m (Specialization t, SpecializedNetwork)
makeSpecialization specif gen = error "Luna.Syntax.Symbol.Map.makeSpecialization: not implemented"


specificationMatch :: (Monad m, RefReader t (ExceptT Bool m) t0) => Specification (Ref t) -> Specialization (Ref t) -> m Bool
specificationMatch specif special = fmap (either id id) $ runExceptT $ do
    let
        arg    (NamedArg n a) = (n, a)
        unarg' (NamedArg _ a) = a
        test m = ifM m (return True) (throwE False)

    -- test positional args
    let specifPositional = specif ^. args . positional
        specialPositional' = special ^. args . positional
        more = length specifPositional - length specialPositional'
    (specialPositional, specialNamed) <- if more >= 0
            then do
                let (p, n) = splitAt more $ special ^.args . named
                return (specialPositional' ++ map unarg' p, n)
            else throwE False
    test $ allM (uncurry (typeMatch)) $ zip specifPositional specialPositional

    -- test optional result
    let specifResult = specif ^. result
        specialResult = special ^. result

    test $ case specifResult of
        Just s -> typeMatch s specialResult
        Nothing -> return True

    -- test named args
    let specialNamed = Map.fromList $ map arg $ special ^. args . named
        argMatch (n, a) = typeMatch a =<< Map.lookup n specialNamed <??> False
    test $ allM argMatch $ Map.toList $ specif ^. args . named


typeMatch :: (Monad m, RefReader t m t0) => Ref t -> Ref t -> m Bool
typeMatch t1 t2 = do
    t1' <- readRef t1
    t2' <- readRef t2
    -- return $ fromEnum t1' == fromEnum t2'
    return $ error "Luna.Syntax.Symbol.Map.typesMatch: Not implemented" --
