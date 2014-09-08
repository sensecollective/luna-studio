{-# LANGUAGE ScopedTypeVariables #-}

module Test.Luna.Typechecker.Internal.TIMonadSpec (spec) where

--import Luna.Typechecker.Internal.AST.Alternatives as Alt
--import Luna.Typechecker.Internal.AST.Common       as Cmm
--import Luna.Typechecker.Internal.AST.Expr         as Exp
import Luna.Typechecker.Internal.AST.Kind
--import Luna.Typechecker.Internal.AST.Lit          as Lit
--import Luna.Typechecker.Internal.AST.Module       as Mod
--import Luna.Typechecker.Internal.AST.Pat          as Pat
import Luna.Typechecker.Internal.AST.Scheme
--import Luna.Typechecker.Internal.AST.TID          as TID
import Luna.Typechecker.Internal.AST.Type


--import Luna.Typechecker.Internal.Ambiguity        as Amb
--import Luna.Typechecker.Internal.Assumptions      as Ass
--import Luna.Typechecker.Internal.BindingGroups    as Bnd
--import Luna.Typechecker.Internal.ContextReduction as CxR
--import Luna.Typechecker.Internal.HasKind          as HKd
--import Luna.Typechecker.Internal.Substitutions    as Sub
import Luna.Typechecker.Internal.TIMonad
import Luna.Typechecker.Internal.Typeclasses
--import Luna.Typechecker.Internal.TypeInference    as Inf
--import Luna.Typechecker.Internal.Unification      as Uni
--import Luna.Typechecker                           as Typechecker

import Test.Luna.Typechecker.Internal.AST.TypeGen (genTypeNogen,genPredNogen)

import Test.Hspec
import Test.QuickCheck

spec :: Spec
spec = do
  describe "freshInst" $ do
    
    it "works for simple types [QC]" $ property $ 
      forAll (genTypeNogen Star) $ \t -> do
        let qt = ([] :=> t)
            x  = runTI $ freshInst (Forall [] qt)
        x `shouldBe` qt

    it "works with one predicate" $ do
      let a  = (TVar $ Tyvar "a" Star)
          ps = [ IsIn "Integral" a ]
          qt = ps :=> (a `fn` a)
          x  = runTI $ freshInst (Forall [] qt)
      x `shouldBe` qt

    it "works with one predicate and one gen-var" $ do
      let a  = TGen 0
          ps = [ IsIn "Integral" a ]
          qt = ps :=> (a `fn` a)
          ([IsIn "Integral" t'] :=> t'') = runTI $ freshInst (Forall [Star] qt)
      t'' `shouldBe` (t' `fn` t')

  describe "(internals)" $ do
    describe "class Instantiate t" $ do
      describe "instance Instantiate a => Instantiate [a]" $ do
        it "inst [] is an identity for x::Type  (no TGen inside!) [qc]" $ property $
          forAll arbitrary        $ \k ->
          forAll (genTypeNogen k) $ \x ->
            inst [] (x::Type) `shouldBe` x
        it "inst [] is an identity for x::(Qual Type)  (no TGen inside!) [qc]" $ property $
          forAll arbitrary         $ \k1  ->
          forAll arbitrary         $ \k2  ->
          forAll (genPredNogen k1) $ \ps ->
          forAll (genTypeNogen k2) $ \t  ->
            inst [] ([ps] :=> t) `shouldBe` ([ps] :=> t)
        it "inst [] is an identity for x::Pred  (no TGen inside!) [qc]" $ property $
          forAll arbitrary        $ \c  ->
          forAll arbitrary        $ \k  ->
          forAll (genTypeNogen k) $ \t  ->
            inst [] (IsIn c t) `shouldBe` (IsIn c t)
