module Main exposing (..)

import Article exposing (Article, Articles)
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, article, h2, h3, text)
import Html.Attributes as Attr exposing (href, id)
import Http
import RequestStatus exposing (RequestStatus(..))
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, parse, s, string, top)



-- MAIN


main : Program () Model Msg
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
    , articles : Articles
    , editingArticle : Maybe Article
    , status : RequestStatus
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        model =
            { key = key
            , route = IndexArticles
            , articles = Article.none
            , editingArticle = Nothing
            , status = Idle
            }
    in
    updateRoute url model



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotArticles (Result Http.Error Articles)
    | GotArticleBody (Result Http.Error Article)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            updateRoute url model

        GotArticles result ->
            case result of
                Ok articles ->
                    ( { model | articles = articles, status = Idle }, Cmd.none )

                Err e ->
                    ( { model | status = Problem "Could not fetch articles from backend" }, Cmd.none )

        GotArticleBody result ->
            case result of
                Ok art ->
                    ( { model | editingArticle = Just art, status = Idle }, Cmd.none )

                Err e ->
                    ( { model | status = Problem "Could not fetch article from backend" }, Cmd.none )


updateRoute : Url.Url -> Model -> ( Model, Cmd Msg )
updateRoute url model =
    let
        newRoute =
            parse routeParser url
                |> Maybe.withDefault NotFound

        newModel =
            { model | route = newRoute }
    in
    case newRoute of
        IndexArticles ->
            ( { newModel | status = Fetching }, fetchArticles )

        EditArticle artId ->
            ( { newModel | status = Fetching }, fetchArticleBody artId )

        _ ->
            ( newModel, Cmd.none )



-- ROUTES


type Route
    = IndexArticles
    | EditArticle Article.Id
    | NotFound


routeParser : Parser (Route -> a) a
routeParser =
    s "admin"
        </> oneOf
                [ map IndexArticles top
                , map EditArticle (s "articles" </> string)
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

        EditArticle id ->
            case model.editingArticle of
                Just art ->
                    viewArticleEdit art

                Nothing ->
                    viewNotFound

        NotFound ->
            viewNotFound


viewNotFound : Browser.Document Msg
viewNotFound =
    { title = "Not found", body = [ text "Route not found" ] }


viewArticlesIndex : Model -> Browser.Document Msg
viewArticlesIndex model =
    { title = "Articles"
    , body = List.map viewArticleListing model.articles
    }


viewArticleListing : Article -> Html Msg
viewArticleListing art =
    article [ id art.id ]
        [ h3 [] [ text art.title ]
        , a [ href ("/admin/articles/" ++ art.id) ] [ text "edit" ]
        ]


viewArticleEdit : Article -> Browser.Document Msg
viewArticleEdit art =
    { title = "Editing article '" ++ art.title ++ "'"
    , body =
        [ article [ id art.id ]
            [ h2 [] [ text art.title ]
            ]
        ]
    }



-- CMD


fetchArticles : Cmd Msg
fetchArticles =
    Http.get
        { url = "/api/articles"
        , expect = Http.expectJson GotArticles Article.listDecoder
        }


fetchArticleBody : Article.Id -> Cmd Msg
fetchArticleBody artId =
    Http.get
        { url = "/api/articles/" ++ artId
        , expect = Http.expectJson GotArticleBody Article.decoder
        }
