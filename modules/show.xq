xquery version "3.1";

(:~ A main module to retrieve a tweet. :)

import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";

(: Parameters needed for the statuses/show function. :)

let $id := xs:unsignedLong(590844951161872384)
let $trim-user := false()
let $include-my-retweet := true()
let $include-entities := true()
let $request-response := 
    twitter:show(
        config:consumer-key(), 
        config:consumer-secret(), 
        config:access-token(), 
        config:access-token-secret(), 
        $id, 
        $trim-user, 
        $include-my-retweet, 
        $include-entities
    )
return
    twitter:echo-response($request-response)