module Main exposing (..)

import Article exposing (Article, Articles)
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, article, button, div, form, h1, h2, h3, input, label, span, text, textarea)
import Html.Attributes exposing (disabled, for, href, id, name, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Markdown.Parser as Markdown
import Markdown.Renderer
import RequestStatus exposing (RequestStatus(..))
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, string, top)



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
    | ChangedArticle EditArticleMsg
    | SaveArticle


type EditArticleMsg
    = ChangedBody String
    | ChangedSlug String
    | ChangedTitle String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        noop =
            ( model, Cmd.none )
    in
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
                    ( { model | articles = articles, editingArticle = Nothing, status = Idle }, Cmd.none )

                Err e ->
                    ( { model | status = Problem "Could not fetch articles from backend" }, Cmd.none )

        GotArticleBody result ->
            case result of
                Ok art ->
                    ( { model | editingArticle = Just art, status = Idle }, Cmd.none )

                Err e ->
                    ( { model | status = Problem "Could not fetch article from backend" }, Cmd.none )

        ChangedArticle editMsg ->
            case model.editingArticle of
                Just art ->
                    ( { model | editingArticle = Just (updateArticle editMsg art) }, Cmd.none )

                Nothing ->
                    noop

        SaveArticle ->
            case model.editingArticle of
                Just art ->
                    ( { model | status = Fetching }, saveArticle art )

                Nothing ->
                    noop


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


updateArticle : EditArticleMsg -> Article -> Article
updateArticle msg art =
    let
        unsaved =
            { art | saved = False }
    in
    case msg of
        ChangedBody body ->
            { unsaved | body = body }

        ChangedSlug slug ->
            { unsaved | slug = slug }

        ChangedTitle title ->
            { unsaved | title = title }



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
    let
        field label_ inputType val_ toEditMsg =
            div []
                [ label [ for label_ ] [ text label_ ]
                , div []
                    [ input
                        [ type_ inputType
                        , value val_
                        , name label_
                        , onInput (\s -> ChangedArticle (toEditMsg s))
                        ]
                        []
                    ]
                ]

        titleField =
            field "Title" "text" art.title ChangedTitle

        bodyField =
            div []
                [ label [ for "Body" ] [ text "Body" ]
                , div []
                    [ textarea
                        [ value art.body
                        , name "Body"
                        , onInput (\s -> ChangedArticle (ChangedBody s))
                        ]
                        []
                    ]
                ]

        slugField =
            field "Slug" "text" art.slug ChangedSlug

        submit =
            button [ onClick SaveArticle, disabled art.saved ] [ text "Save" ]

        updatedAt =
            span [] [ text ("Last saved: " ++ art.updatedAt) ]

        backLink =
            a [ href "/admin" ] [ text "Back" ]

        preview =
            article []
                [ h1 [] [ text art.title ]
                , div [] [ viewMarkdown art.body ]
                ]
    in
    { title = "Editing article '" ++ art.title ++ "'"
    , body =
        [ form
            [ id ("edit_" ++ art.id)
            , onSubmit SaveArticle
            ]
            [ titleField
            , bodyField
            , slugField
            , div []
                [ backLink
                , submit
                ]
            , updatedAt
            ]
        , preview
        ]
    }


viewMarkdown : String -> Html Msg
viewMarkdown string =
    case
        string
            |> Markdown.parse
            |> Result.mapError deadEndsToString
            |> Result.andThen (\ast -> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast)
    of
        Ok rendered ->
            div [] rendered

        Err errors ->
            text errors


deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.deadEndToString
        |> String.join "\n"



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


saveArticle : Article -> Cmd Msg
saveArticle art =
    Http.post
        { url = "/api/articles/" ++ art.id
        , body = Http.jsonBody (Article.encode art)
        , expect = Http.expectJson GotArticleBody Article.decoder
        }
