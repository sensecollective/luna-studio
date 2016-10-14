"use strict";

module.exports = function() {
  // required for interactive
  window.app            = require('app');
  window.common         = require('common');
  window.config         = require('config');
  window.breadcrumb     = require('breadcrumb');
  window.raycaster      = require('raycaster');
  window.connectionPen  = require('connection_pen');
  window.Slider         = require('Widget/Slider');
  window.Toggle         = require('Widget/Toggle');
  window.TextBox        = require('Widget/TextBox');
  // window.RadioButton    = require('Widget/RadioButton');
  window.Connection     = require('Widget/Connection');
  window.textEditor     = require('text_editor');
  window.GraphNode      = require('Widget/Node');
  window.Group          = require('Widget/Group');
  window.Port           = require('Widget/Port');
  window.Button         = require('Widget/Button');
  window.Label          = require('Widget/Label');
  window.LabeledWidget  = require('Widget/LabeledWidget');
  window.Icon           = require('Widget/Icon');
  window.PlotImage      = require('Widget/Image');
  window.LongText       = require('Widget/Text');
  window.DataFrame      = require('Widget/DataFrame');
  window.CodeEditor     = require('Widget/CodeEditor');
  window.Graphics       = require('Widget/Graphics');
  window.h$errorMsg     = require("BSOD").appCrashed;
};
