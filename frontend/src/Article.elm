module Article exposing
    ( Article
    , Articles
    , Id
    , decoder
    , encode
    , listDecoder
    , new
    , none
    )

import Json.Decode as JD exposing (Decoder, field, list, string, succeed)
import Json.Encode as JE exposing (object)


type alias Article =
    { id : Id
    , title : String
    , slug : String
    , body : String
    , updatedAt : String
    , saved : Bool
    }


new : Article
new =
    { id = ""
    , title = ""
    , slug = ""
    , body = ""
    , updatedAt = "never"
    , saved = False
    }


type alias Articles =
    List Article


none : Articles
none =
    []


type alias Id =
    String



-- JSON


decoder : Decoder Article
decoder =
    field "article" <|
        JD.map6 Article
            (field "id" string)
            (field "title" string)
            (field "slug" string)
            (field "body" string)
            (field "updated_at" string)
            (succeed True)


listDecoder : Decoder Articles
listDecoder =
    field "articles" (list metaOnlyDecoder)


metaOnlyDecoder : Decoder Article
metaOnlyDecoder =
    JD.map6 Article
        (field "id" string)
        (field "title" string)
        (field "slug" string)
        (succeed "")
        (field "updated_at" string)
        (succeed True)


encode : Article -> JE.Value
encode art =
    object
        [ ( "title"
          , JE.string art.title
          )
        , ( "slug"
          , JE.string art.slug
          )
        , ( "body"
          , JE.string art.body
          )
        ]
