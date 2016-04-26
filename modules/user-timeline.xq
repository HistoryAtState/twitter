xquery version "3.1";

(:~ A main module to retrieve the user timeline. :)

import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";
import module namespace ju = "http://joewiz.org/ns/xquery/json-util" at "json-util.xqm";

(: Parameters needed for the user timeline function. :)

let $user-id := ()
let $screen-name := ()
let $since-id := ()
let $count := 10
let $max-id := ()
let $trim-user := true()
let $exclude-replies := false()
let $contributor-details := false()
let $include-rts := false()
let $request-response := 
    twitter:user-timeline(
        config:consumer-key(),
        config:consumer-secret(),
        config:access-token(),
        config:access-token-secret(),
        $user-id, 
        $screen-name, 
        $since-id, 
        $count, 
        $max-id, 
        $trim-user, 
        $exclude-replies, 
        $contributor-details, 
        $include-rts
    )
return
    twitter:echo-response($request-response)