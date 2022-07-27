module Article exposing
    ( Article
    , Articles
    , Id
    , encode
    , listDecoder
    , new
    , none
    , pathTo
    , singleDecoder
    , slugify
    )

import Json.Decode as JD exposing (Decoder, field, list, string, succeed)
import Json.Encode as JE exposing (object)
import Slug


type alias Article =
    { id : Id
    , title : String
    , slug : String
    , body : String
    , updatedAt : String
    , slugSet : Bool
    , saved : Bool
    }


new : Article
new =
    { id = ""
    , title = ""
    , slug = ""
    , body = ""
    , updatedAt = "never"
    , slugSet = False
    , saved = False
    }


type alias Articles =
    List Article


none : Articles
none =
    []


type alias Id =
    String


slugify : String -> Maybe String
slugify s =
    Maybe.map Slug.toString (Slug.generate s)



-- JSON


singleDecoder : Decoder Article
singleDecoder =
    field "article" (decodeWithBody <| field "body" <| JD.oneOf [ string, succeed "" ])


decodeWithBody : Decoder String -> Decoder Article
decodeWithBody bodyDecoder =
    JD.map7 Article
        (field "id" string)
        (field "title" <| JD.oneOf [ string, succeed "" ])
        (field "slug" <| JD.oneOf [ string, succeed "" ])
        bodyDecoder
        (field "updated_at" string)
        (field "slug" (JD.nullable JD.string) |> JD.andThen (\maybeSlug -> JD.succeed (maybeSlug /= Nothing)))
        (succeed True)


listDecoder : Decoder Articles
listDecoder =
    field "articles" (list <| decodeWithBody (JD.succeed ""))


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



-- VIEW


pathTo : Article -> String
pathTo art =
    "/admin/articles/" ++ art.id
