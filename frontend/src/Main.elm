module Main exposing (..)

import Article exposing (Article, Articles)
import Browser
import Browser.Navigation as Nav
import Html exposing (Html, a, article, aside, button, div, form, h1, h2, h3, header, input, label, main_, p, span, text, textarea)
import Html.Attributes exposing (disabled, for, href, id, name, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Markdown.Parser as Markdown
import Markdown.Renderer
import Maybe.Extra exposing (or)
import RequestStatus exposing (RequestStatus(..))
import Tachyons exposing (classes)
import Tachyons.Classes as T
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, string, top)
import Validations



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
    | CreateArticle


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
                    ( { model
                        | articles = articles
                        , editingArticle = Nothing
                        , status = Idle
                      }
                    , Cmd.none
                    )

                Err e ->
                    let
                        _ =
                            Debug.log "Error fetching articles: " e
                    in
                    ( { model | status = Problem "Could not fetch articles from backend" }, Cmd.none )

        GotArticleBody result ->
            case result of
                Ok art ->
                    ( { model
                        | editingArticle = Just art
                        , status = Idle
                        , route = EditArticle art.id
                      }
                    , Cmd.none
                    )

                Err e ->
                    let
                        problemDescription =
                            case e of
                                Http.BadStatus 422 ->
                                    "Could not save this article because of the problems described below..."

                                _ ->
                                    "There was an error communicating with the database."
                    in
                    ( { model | status = Problem problemDescription }, Cmd.none )

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

        CreateArticle ->
            ( model, createArticle )


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
            { unsaved
                | slug = slug
                , slugSet = True
            }

        ChangedTitle title ->
            { unsaved
                | title = title
                , slug =
                    if art.slugSet then
                        art.slug

                    else
                        Maybe.withDefault "" (Article.slugify title)
            }



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
                    viewArticleEdit art model

                Nothing ->
                    viewArticleEdit Article.new model

        NotFound ->
            viewNotFound


layout : { title : String, status : RequestStatus, body : List (Html Msg) } -> Browser.Document Msg
layout { title, status, body } =
    { title = title
    , body =
        [ div [ classes [ T.sans_serif ] ]
            [ header
                [ classes
                    [ T.bb
                    , T.mb2
                    , T.bb_0_ns
                    , T.b__light_gray
                    , T.b__dotted
                    , T.bt_0
                    , T.bl_0
                    , T.br_0
                    , T.w_100
                    , T.ph3
                    , T.pv3
                    , T.pv4_ns
                    , T.ph4_m
                    , T.ph5_l
                    , T.flex
                    , T.justify_between
                    , T.items_center
                    ]
                ]
                [ div [ classes [ T.flex, T.items_center, T.justify_between ] ]
                    [ a
                        [ href "/admin"
                        , classes [ T.fw6, T.link, T.black ]
                        ]
                        [ text "Admin dashboard" ]
                    ]
                , a
                    [ href "/"
                    , classes
                        [ T.f6
                        , T.link
                        , T.br2
                        , T.ph3
                        , T.pv2
                        , T.dib
                        , T.black
                        , T.bg_light_gray
                        , T.bg_animate
                        , T.hover_bg_moon_gray
                        ]
                    ]
                    [ text "View site" ]
                ]
            , div
                [ classes [ T.flex, T.flex_column, T.items_center ] ]
                [ main_ [ classes [ T.ph3, T.ph4_ns, T.w_100, T.flex, T.flex_column, T.items_center ] ] <|
                    RequestStatus.view status
                        :: body
                ]
            ]
        ]
    }


viewNotFound : Browser.Document Msg
viewNotFound =
    { title = "Not found", body = [ text "Route not found" ] }


viewArticlesIndex : Model -> Browser.Document Msg
viewArticlesIndex model =
    layout
        { title = "Articles"
        , status = model.status
        , body =
            [ div [ classes [ T.w_two_thirds_ns ] ]
                [ div
                    [ classes
                        [ T.flex
                        , T.items_center

                        -- On large screens
                        , T.justify_between_ns
                        , T.flex_row_ns

                        -- On phone screens
                        , T.flex_column
                        , T.justify_start
                        ]
                    ]
                    [ h1 [] [ text "Articles" ]
                    , button
                        [ onClick CreateArticle
                        , classes
                            [ T.f6
                            , T.link
                            , T.br2
                            , T.ph3
                            , T.pv2
                            , T.mb2
                            , T.dib
                            , T.white
                            , T.bg_blue
                            , T.hover_bg_white
                            , T.hover_blue
                            , T.bg_animate
                            , T.ba
                            , T.b__blue
                            ]
                        ]
                        [ text "New article" ]
                    ]
                , div [ classes [ T.mt4 ] ] <|
                    List.map viewArticleListing model.articles
                ]
            ]
        }


viewArticleListing : Article -> Html Msg
viewArticleListing art =
    a
        [ href (Article.pathTo art)
        , classes [ T.black, T.link ]
        ]
        [ article
            [ id art.id
            , classes
                [ T.flex
                , T.items_center
                , T.justify_between
                , T.br3
                , T.ba
                , T.b__black_10
                , T.ph4
                , T.mb2
                , T.flex
                , T.items_center
                , T.justify_between
                , T.hover_bg_washed_yellow
                , T.bg_animate
                ]
            ]
            [ h3 []
                [ if art.title == "" then
                    span [ classes [ T.o_40 ] ] [ text "No title" ]

                  else
                    text art.title
                ]
            ]
        ]


viewArticleEdit : Article -> Model -> Browser.Document Msg
viewArticleEdit art model =
    let
        label_ name_ =
            label [ for name_, classes [ T.f6, T.b, T.db, T.mb2 ] ] [ text name_ ]

        inputClasses =
            [ T.input_reset, T.ba, T.b__black_20, T.br2, T.pa2, T.mb2, T.db, T.w_100 ]

        hint message =
            aside [ classes [ T.f6, T.black_60, T.db, T.mb2 ] ] [ text message ]

        errMessage name_ maybeErr =
            case maybeErr of
                Just err ->
                    aside [ classes [ T.f6, T.red, T.db, T.mb2 ] ]
                        [ text <| name_ ++ " " ++ err ]

                Nothing ->
                    text ""

        field name_ inputType val_ toEditMsg maybeErr hint_ =
            div
                [ classes
                    [ T.mb3
                    , T.measure
                    ]
                ]
                [ label_ name_
                , hint hint_
                , div []
                    [ input
                        [ type_ inputType
                        , value val_
                        , name name_
                        , classes
                            (inputClasses
                                ++ (case maybeErr of
                                        Just _ ->
                                            [ T.red ]

                                        _ ->
                                            []
                                   )
                            )
                        , onInput (\s -> ChangedArticle (toEditMsg s))
                        ]
                        []
                    ]
                , errMessage name_ maybeErr
                ]

        titleField =
            field "Title" "text" art.title ChangedTitle (Validations.required art.title) ""

        bodyField =
            div []
                [ label_ "Body"
                , div []
                    [ textarea
                        [ value art.body
                        , name "Body"
                        , classes (inputClasses ++ [ T.h5 ])
                        , onInput (\s -> ChangedArticle (ChangedBody s))
                        ]
                        []
                    ]
                ]

        slugField =
            let
                otherSlugs =
                    model.articles |> List.filter (\a -> a.id /= art.id) |> List.map .slug
            in
            field "Slug"
                "text"
                art.slug
                ChangedSlug
                (Validations.unique otherSlugs art.slug
                    |> or (Validations.required art.slug)
                )
                ("Your article will be published at " ++ "/" ++ art.slug)

        submit =
            button
                [ onClick SaveArticle
                , disabled art.saved
                , classes <|
                    [ T.input_reset
                    , T.button_reset
                    , T.f6
                    , T.w5
                    , T.link
                    , T.br2
                    , T.ph3
                    , T.pv2
                    , T.mb2
                    , T.dib
                    , T.ba
                    ]
                        ++ (if art.saved then
                                []

                            else
                                [ T.white
                                , T.bg_blue
                                , T.hover_bg_white
                                , T.hover_blue
                                , T.bg_animate
                                , T.b__blue
                                , T.pointer
                                ]
                           )
                ]
                [ text "Save" ]

        updatedAt =
            hint ("Last saved: " ++ art.updatedAt)

        preview =
            div [ classes [ T.ph4 ] ]
                [ article [ classes [ T.mb5 ] ]
                    [ h1 [] [ text art.title ]
                    , div [] [ viewMarkdown art.body ]
                    ]
                , hint "Article preview"
                , updatedAt
                ]
    in
    layout
        { title = "Editing article"
        , status = model.status
        , body =
            [ div [ classes [ T.w_100, T.flex, T.flex_row_ns, T.flex_column ] ]
                [ form
                    [ id ("edit_" ++ art.id)
                    , onSubmit SaveArticle
                    , classes [ T.bg_light_gray, T.br2, T.pa4, T.flex, T.flex_column, T.black_80 ]
                    ]
                    [ titleField
                    , bodyField
                    , slugField
                    , div
                        [ classes
                            [ T.flex
                            , T.flex_column
                            , T.items_center
                            , T.justify_center
                            , T.mt3
                            ]
                        ]
                        [ submit
                        ]
                    ]
                , preview
                ]
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
        { url = "/admin/api/articles"
        , expect = Http.expectJson GotArticles Article.listDecoder
        }


fetchArticleBody : Article.Id -> Cmd Msg
fetchArticleBody artId =
    Http.get
        { url = "/admin/api/articles/" ++ artId
        , expect = Http.expectJson GotArticleBody Article.singleDecoder
        }


saveArticle : Article -> Cmd Msg
saveArticle art =
    Http.post
        { url = "/admin/api/articles/" ++ art.id
        , body = Http.jsonBody (Article.encode art)
        , expect = Http.expectJson GotArticleBody Article.singleDecoder
        }


createArticle : Cmd Msg
createArticle =
    Http.post
        { url = "/admin/api/articles"
        , body = Http.emptyBody
        , expect = Http.expectJson GotArticleBody Article.singleDecoder
        }
