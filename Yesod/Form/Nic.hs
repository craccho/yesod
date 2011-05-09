{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoMonomorphismRestriction #-} -- FIXME remove
-- | Provide the user with a rich text editor.
module Yesod.Form.Nic
    ( YesodNic (..)
    , nicHtmlField
    ) where

import Yesod.Handler
import Yesod.Form
import Yesod.Widget
import Text.HTML.SanitizeXSS (sanitizeBalance)
import Text.Hamlet (Html, hamlet)
import Text.Julius (julius)
import Text.Blaze.Renderer.String (renderHtml)
import Text.Blaze (preEscapedString)
import Control.Monad.Trans.Class (lift)
import Data.Text (Text, pack, unpack)

class YesodNic a where
    -- | NIC Editor Javascript file.
    urlNicEdit :: a -> Either (Route a) Text
    urlNicEdit _ = Right "http://js.nicedit.com/nicEdit-latest.js"

nicHtmlField :: YesodNic master => Field (GWidget sub master ()) Html
nicHtmlField = Field
    { fieldParse = Right . preEscapedString . sanitizeBalance . unpack -- FIXME
    , fieldRender = pack . renderHtml
    , fieldView = \theId name val _isReq -> do
        addHtml
#if __GLASGOW_HASKELL__ >= 700
                [hamlet|
#else
                [$hamlet|
#endif
    <textarea id="#{theId}" name="#{name}" .html>#{val}
|]
        addScript' urlNicEdit
        addJulius
#if __GLASGOW_HASKELL__ >= 700
                [julius|
#else
                [$julius|
#endif
bkLib.onDomLoaded(function(){new nicEditor({fullPanel:true}).panelInstance("#{theId}")});
|]
    }

addScript' :: (y -> Either (Route y) Text) -> GWidget sub y ()
addScript' f = do
    y <- lift getYesod
    addScriptEither $ f y
