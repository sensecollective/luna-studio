{-# LANGUAGE OverloadedStrings #-}
module Reactive.Plugins.Core.Action.Init where

import qualified Data.IntMap.Lazy                           as IntMap
import           Utils.PreludePlus
import           Utils.Vector                               (Vector2 (..))

import           Object.UITypes                             (WidgetId)
import qualified Object.Widget.Button                       as Button
import qualified Object.Widget.Group                        as Group
import           Reactive.Commands.Command                  (Command, execCommand, performIO)
import           Reactive.Commands.CommandSearcher.Commands (toggleText)
import           Reactive.Commands.ProjectManager           (displayCurrentBreadcrumb)
import qualified Reactive.Commands.UIRegistry               as UICmd
import           Reactive.State.Global                      (State, inRegistry)
import qualified Reactive.State.Global                      as Global
import qualified Reactive.State.UIElements                  as UIElements
import           Reactive.State.UIRegistry                  (addHandler, handle, sceneInterfaceId)
import qualified Reactive.State.UIRegistry                  as UIRegistry
import qualified Style.Layout                               as Style
import           Style.Types                                (uniformPadding, xyPadding)
import qualified UI.Handlers.Button                         as Button
import qualified UI.Layout                                  as Layout

initSidebar :: Command State WidgetId
initSidebar = do
    let group = Group.create & Group.style .~ Style.sidebar
                             & Group.size  .~ Vector2 Style.sidebarWidth 1000
    sidebar <- inRegistry $ UICmd.register sceneInterfaceId group def
    Global.uiElements . UIElements.sidebar .= sidebar
    return sidebar

initBreadcrumb :: Command State ()
initBreadcrumb = do
    let group = Group.create & Group.position  .~ Style.breadcrumbPosition
                             & Group.style     .~ Style.breadcrumbStyle
    groupId <- inRegistry $ UICmd.register sceneInterfaceId group (Layout.horizontalLayoutHandlerNoResize 5.0)
    Global.uiElements . UIElements.breadcrumbs .= groupId

initTextEditor = do
    let toggle = Style.textEditorToggle
    toggleId <- inRegistry $ UICmd.register sceneInterfaceId toggle $ addHandler (Button.ClickedHandler $ const $ toggleText) mempty

    Global.uiElements . UIElements.textEditorToggle .= toggleId

initialize :: Command State ()
initialize = do
    sidebarId <- initSidebar
    initBreadcrumb
    initTextEditor
