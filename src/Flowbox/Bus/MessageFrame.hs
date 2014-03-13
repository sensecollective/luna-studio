---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Flowbox Team <contact@flowbox.io>, 2014
-- Proprietary and confidential
-- Unauthorized copying of this file, via any medium is strictly prohibited
---------------------------------------------------------------------------
module Flowbox.Bus.MessageFrame where

import           Data.ByteString       (ByteString)
import qualified Data.ByteString       as ByteString
import qualified Data.ByteString.Char8 as Char8

import           Flowbox.Bus.Message (Message (Message))
import qualified Flowbox.Bus.Message as M
import qualified Flowbox.Bus.Topic   as Topic
import           Flowbox.Prelude


data MessageFrame = MessageFrame { message     :: Message
                                 , correlation :: M.CorrelationID
                                 , senderID    :: M.ClientID
                                 } deriving (Read, Show, Eq)


separator :: Char
separator = ' '

separator' :: ByteString
separator' = Char8.singleton separator

encode :: (Show a, Read a) => a -> ByteString
encode = Char8.pack . show


decode :: (Show a, Read a) => ByteString -> a
decode = read . Char8.unpack


toByteString :: MessageFrame -> ByteString
toByteString (MessageFrame (Message topic message')
                           (M.CorrelationID clientID messageID)
                           senderID'
             ) =
    ByteString.intercalate separator'
                           [ Topic.toByteString topic
                               , encode clientID
                               , encode messageID
                           , encode senderID'
                           , message'
                           ]


fromByteString :: ByteString -> Either String MessageFrame
fromByteString bs = case splitFirsts 5 separator bs of
    [topic, clientID, messageID, senderID', message']
          -> Right $ MessageFrame (Message (Topic.fromByteString topic) message')
                                  (M.CorrelationID (decode clientID) (decode messageID))
                                  (decode senderID')
    wrong -> Left $ "Cannot parse message" ++ show wrong


splitFirsts :: Int -> Char -> ByteString -> [ByteString]
splitFirsts count sep list =
    if count > 1
        then a : (splitFirsts (count - 1) sep $ Char8.tail b)
        else [list]
    where (a, b) = Char8.break (== sep) list
