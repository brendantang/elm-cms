module RequestStatus exposing (RequestStatus(..), view)

import Html exposing (Html, div, text)
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
    div [ classes [ T.w4 ] ]
        [ case status of
            Idle ->
                text ""

            Fetching ->
                spinner

            Problem description ->
                text "Problem!"
        ]


spinner : Html msg
spinner =
    div [ class "lds-ellipsis" ] <| List.repeat 4 (div [] [])
