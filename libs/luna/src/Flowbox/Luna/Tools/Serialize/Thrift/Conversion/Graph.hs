---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE FlexibleContexts, FlexibleInstances, MultiParamTypeClasses, TypeSynonymInstances #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module Flowbox.Luna.Tools.Serialize.Thrift.Conversion.Graph where

--import Control.Monad
import           Flowbox.Prelude                                        
import qualified Data.Graph.Inductive.Graph                             
import qualified Data.HashMap.Strict                                  as HashMap
import           Data.HashMap.Strict                                    (HashMap)

import           Data.Int                                               
import qualified Data.Text.Lazy                                       as Text
import qualified Data.Vector                                          as Vector

import qualified Attrs_Types                                          as TAttrs
import qualified Graph_Types                                          as TGraph
import           Flowbox.Luna.Network.Attributes                        (Attributes)
import           Flowbox.Luna.Network.Flags                             (Flags(..))
import           Flowbox.Luna.Network.Graph.DefaultValue                (DefaultValue(..))
import qualified Flowbox.Luna.Network.Graph.Edge                      as Edge
import           Flowbox.Luna.Network.Graph.Edge                        (Edge(..))
import qualified Flowbox.Luna.Network.Graph.Graph                     as Graph
import           Flowbox.Luna.Network.Graph.Graph                       (Graph)
import qualified Flowbox.Luna.Network.Graph.Node                      as Node
import           Flowbox.Luna.Network.Graph.Node                        (Node(..))
import           Flowbox.Tools.Conversion                               
import           Flowbox.Luna.Tools.Serialize.Thrift.Conversion.Attrs   ()


encodeGraph :: (Convert (Int, t) v, Convert (Graph.LEdge b) a,
                Data.Graph.Inductive.Graph.Graph gr) 
            => gr t b -> (Maybe (HashMap Int32 v), Maybe (Vector.Vector a))
encodeGraph agraph = (Just nodes, Just edges) where 
    nodes = HashMap.fromList $
        map (\(a, b) -> (itoi32 a, encode (a, b))) $ Graph.labNodes agraph
    edges =  Vector.fromList $ map encode $ Graph.labEdges agraph
     

decodeGraph :: (Data.Graph.Inductive.Graph.Graph gr, Convert (Graph.LEdge b) a)
            => (Maybe (HashMap Int32 TGraph.Node), Maybe (Vector.Vector a))
            -> Either [Char] (gr Node b)
decodeGraph (mtnodes, mtedges) = case mtnodes of
    Nothing    -> Left "`nodes` field is missing"
    Just tnodes -> case mtedges of
        Nothing    -> Left "Edges are not defined" 
        Just tedges ->
            let transformNode :: (Int32, TGraph.Node) -> Either String (Int, Node)
                transformNode (i, lab) = case decode lab of
                    Left msg         -> Left msg
                    Right (_, node)  -> Right (i32toi i, node)
                goodNodes = sequence $ map transformNode $
                    HashMap.toList tnodes 

                goodEdges =  sequence $ map decode $ Vector.toList tedges
            in case goodNodes of
                Left msg         -> Left msg
                Right gnodes     -> case goodEdges of
                    Left msg     -> Left msg
                    Right gedges -> Right $ Graph.mkGraph gnodes gedges


instance Convert (Int, Int, Edge) TGraph.Edge where
  encode (nsrc, ndst, a) =  let 
      adst = itoi32 $ Edge.dst a
    in TGraph.Edge (Just adst) (Just $ itoi32 nsrc) (Just $ itoi32 ndst)
  decode b =
    case TGraph.f_Edge_portDst b of
      Just adst ->
        case TGraph.f_Edge_nodeSrc b of
          Just nodeSrc ->
            case TGraph.f_Edge_nodeDst b of
              Just nodeDst ->
                Right $ (i32toi nodeSrc, i32toi nodeDst, Edge (i32toi adst))
              Nothing      -> Left "No destination node specified"
          Nothing      ->  Left "No source node specified"
      Nothing  -> Left "No destination port specified"


instance Convert Graph TGraph.Graph where
    encode agraph = TGraph.Graph n e where 
        (n, e) = encodeGraph agraph
    decode (TGraph.Graph mtnodes mtedges) = decodeGraph (mtnodes, mtedges)


instance Convert DefaultValue TGraph.DefaultValue where
  encode a =
    case a of
      DefaultChar   ss -> TGraph.DefaultValue (Just TGraph.StringV) (Just $ Text.pack [ss])
      DefaultInt    ss -> TGraph.DefaultValue (Just TGraph.IntV   ) (Just $ Text.pack ss)
      DefaultString ss -> TGraph.DefaultValue (Just TGraph.StringV) (Just $ Text.pack ss)

  decode b =
    case TGraph.f_DefaultValue_cls b of
      Just TGraph.CharV -> case TGraph.f_DefaultValue_s b of
                              Just ss -> Right $ DefaultChar $ head $ Text.unpack ss
                              Nothing -> Left "No char default value specified"
      Just TGraph.IntV    -> case TGraph.f_DefaultValue_s b of
                              Just ii -> Right $ DefaultInt $ Text.unpack ii
                              Nothing -> Left "No integral default value specified"
      Just TGraph.StringV -> case TGraph.f_DefaultValue_s b of
                              Just ss -> Right $ DefaultString $ Text.unpack ss
                              Nothing -> Left "No string default value specified"
      Nothing -> Left "No default value type specified"    


instance Convert (Int, Node) TGraph.Node where
  encode (nid, a) =
    let
      nodeType :: TGraph.NodeType
      nodeType = case a of
                   Node.Expr    {} -> TGraph.Expr
                   Node.Default {} -> TGraph.Default
                   Node.Inputs  {} -> TGraph.Inputs
                   Node.Outputs {} -> TGraph.Outputs
                   Node.Tuple   {} -> TGraph.Tuple
                   Node.NTuple  {} -> TGraph.NTuple

      nodeExpression :: Maybe Text.Text
      nodeExpression = fmap Text.pack $ case a of
                   Node.Expr texpression _ _ -> Just texpression
                   _                         -> Nothing

      nodeID :: Int32
      nodeID = itoi32 nid

      nodeFlags :: Maybe TAttrs.Flags
      nodeFlags = fmap encode $ case a of
                   Node.Expr  _ aflags _ -> Just aflags
                   Node.Inputs  aflags _ -> Just aflags
                   Node.Outputs aflags _ -> Just aflags
                   Node.Tuple   aflags _ -> Just aflags
                   Node.NTuple  aflags _ -> Just aflags
                   _                     -> Nothing

      nodeAttrs :: TAttrs.Attributes
      nodeAttrs = encode $ Node.attributes a

      defValue :: Maybe TGraph.DefaultValue
      defValue = fmap encode $ case a of
                   Node.Default val _ -> Just val
                   _                  -> Nothing
    in
      TGraph.Node (Just nodeType) nodeExpression (Just nodeID) nodeFlags (Just nodeAttrs) defValue
  decode b =
    let
      gnexpression = case TGraph.f_Node_expression b of
                  Just nexpression -> Right $ Text.unpack nexpression
                  Nothing    -> Left "Node name not defined"

      gID = case TGraph.f_Node_nodeID b of
              Just nid -> Right $ i32toi nid
              Nothing  -> Left "Node ID not defined"

      gflags :: Either String Flags
      gflags = case TGraph.f_Node_flags b of
                 Just nflags -> decode nflags
                 Nothing     -> Left "Node flags not defined"
      
      gattrs :: Either String Attributes
      gattrs = case TGraph.f_Node_attrs b of
                Just nattrs -> decode nattrs
                Nothing     -> Left "Node attributes not defined"

      gdefval :: Either String DefaultValue
      gdefval = case TGraph.f_Node_defVal b of
                 Just ndefval -> decode ndefval
                 Nothing      -> Left "Default value not defined"

      gnode :: Either String Node
      gnode =  case TGraph.f_Node_cls b of
            Just ntype ->
              case ntype of
                TGraph.Expr -> do
                  ggexpression  <- gnexpression
                  ggflags <- gflags
                  ggattrs <- gattrs
                  Right $ Node.Expr ggexpression ggflags ggattrs
                TGraph.Default -> do
                  ggdefval <- gdefval
                  ggattrs  <- gattrs
                  Right $ Node.Default ggdefval ggattrs
                TGraph.Inputs -> do
                  ggflags <- gflags
                  ggattrs <- gattrs
                  Right $ Node.Inputs ggflags ggattrs
                TGraph.Outputs -> do
                  ggflags <- gflags
                  ggattrs <- gattrs
                  Right $ Node.Outputs ggflags ggattrs
                TGraph.Tuple -> do
                  ggflags <- gflags
                  ggattrs <- gattrs
                  Right $ Node.Tuple ggflags ggattrs
                TGraph.NTuple -> do
                  ggflags <- gflags
                  ggattrs <- gattrs
                  Right $ Node.NTuple ggflags ggattrs
            Nothing     -> Left "Node type not defined"

    in
      do
        ggnode <- gnode
        ggID <- gID
        Right $ (ggID, ggnode)
       
  
      
