module RequestStatus exposing (RequestStatus(..))


type RequestStatus
    = Idle
    | Fetching
    | Problem String
