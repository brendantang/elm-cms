module RequestStatus exposing (RequestStatus(..), view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Tachyons exposing (classes)
import Tachyons.Classes as T


type RequestStatus
    = Idle
    | Fetching
    | Problem String



-- VIEW


view : RequestStatus -> Html msg
view status =
    div [ classes [ T.mb2, T.h4, T.flex, T.items_center, T.flex_column, T.justify_center ] ]
        [ case status of
            Idle ->
                text ""

            Fetching ->
                spinner

            Problem description ->
                viewProblem description
        ]


spinner : Html msg
spinner =
    div [ class "lds-ellipsis" ] <| List.repeat 4 (div [] [])


viewProblem : String -> Html msg
viewProblem description =
    div
        [ classes
            [ T.flex
            , T.flex_column
            , T.f6
            , T.items_center
            , T.justify_center
            , T.pa3
            , T.bg_washed_red
            , T.dark_red
            , T.br2
            , T.mb4
            ]
        ]
        [ span [ classes [ T.lh_title, T.b ] ] [ text "Problem! " ]
        , span [] [ text description ]
        ]
