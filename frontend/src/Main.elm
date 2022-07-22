module Main exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html, pre, text)
import Http
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, string, top)



-- MAIN


main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , route : Route
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        model =
            { key = key
            , route = IndexArticles
            }
    in
    updateRoute url model



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            updateRoute url model


updateRoute : Url.Url -> Model -> ( Model, Cmd Msg )
updateRoute url model =
    let
        newRoute =
            parse routeParser url
                |> Maybe.withDefault NotFound
    in
    ( { model | route = newRoute }, Cmd.none )



-- ROUTES


type Route
    = IndexArticles
    | NotFound


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map IndexArticles (s "admin")
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    case model.route of
        IndexArticles ->
            viewArticlesIndex model

        NotFound ->
            viewNotFound


viewNotFound : Browser.Document Msg
viewNotFound =
    { title = "Not found", body = [ text "Route not found" ] }


viewArticlesIndex : Model -> Browser.Document Msg
viewArticlesIndex model =
    { title = "Articles"
    , body =
        [ text (Debug.toString model)
        ]
    }
