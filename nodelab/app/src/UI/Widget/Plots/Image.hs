module UI.Widget.Plots.Image where

import           Utils.PreludePlus
import           Utils.Vector

import           Data.JSString.Text        (lazyTextToJSString)
import           GHCJS.Marshal.Pure        (PFromJSVal (..), PToJSVal (..))
import           GHCJS.Types               (JSString, JSVal)

import           Object.UITypes
import           Object.Widget
import qualified Object.Widget.Plots.Image as Model
import qualified Reactive.State.UIRegistry as UIRegistry

import           JavaScript.Array          (JSArray)
import qualified JavaScript.Array          as JSArray
import           UI.Generic                (whenChanged)
import qualified UI.Generic                as UI
import qualified UI.Registry               as UI
import           UI.Widget                 (UIWidget (..))
import qualified UI.Widget                 as Widget

newtype Image = Image JSVal deriving (PToJSVal, PFromJSVal)


instance UIWidget Image

foreign import javascript safe "new PlotImage($1, $2, $3)" create'  :: Int   -> Double -> Double -> IO Image
foreign import javascript safe "$1.setData($2)"        setData' :: Image -> JSString -> IO ()


create :: WidgetId -> Model.Image -> IO Image
create oid model = do
    plot <- create' oid (model ^. Model.size . x) (model ^. Model.size . y)
    setData' plot $ lazyTextToJSString $ model ^. Model.image
    UI.setWidgetPosition (model ^. widgetPosition) plot
    return plot

instance UIDisplayObject Model.Image where
    createUI parentId id model = do
        plot   <- create id model
        parent <- UI.lookup parentId :: IO Widget.GenericWidget
        UI.register id plot
        Widget.add plot parent

    updateUI id old model = do
        plot <- UI.lookup id :: IO Image
        setData' plot $ lazyTextToJSString $ model ^. Model.image

instance CompositeWidget Model.Image
instance ResizableWidget Model.Image

