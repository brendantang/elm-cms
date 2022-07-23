module Validations exposing (required, unique)


type alias Error =
    String


required : String -> Maybe Error
required string =
    if String.length string == 0 then
        Just "required"

    else
        Nothing


unique : List a -> a -> Maybe Error
unique others attr =
    if List.member attr others then
        Just "taken"

    else
        Nothing
