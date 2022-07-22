module Article exposing
    ( Article
    , Articles
    , Id
    , decoder
    , listDecoder
    , none
    )

import Json.Decode as JD exposing (Decoder, field, list, string)


type alias Article =
    { id : Id
    , title : String
    , body : String
    }


type alias Articles =
    List Article


none : Articles
none =
    []


type alias Id =
    String


decoder : Decoder Article
decoder =
    field "article" <|
        JD.map3 Article
            (field "id" string)
            (field "title" string)
            (field "body" string)


listDecoder : Decoder Articles
listDecoder =
    field "articles" (list metaOnlyDecoder)


metaOnlyDecoder : Decoder Article
metaOnlyDecoder =
    JD.map3 Article
        (field "id" string)
        (field "title" string)
        (JD.succeed "")
