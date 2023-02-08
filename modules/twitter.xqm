xquery version "3.1";

module namespace twitter="http://history.state.gov/ns/xquery/twitter";

(:~ A library module for Twitter API methods. 

    @see https://dev.twitter.com/docs/api/1.1
 :)

import module namespace oauth="http://history.state.gov/ns/xquery/oauth" at "oauth.xqm";
import module namespace util="http://exist-db.org/xquery/util";

declare variable $twitter:api-base-uri := 'https://api.twitter.com/1.1';

(:
    Get the user timeline.
    See https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
:)
declare function twitter:user-timeline(
        $consumer-key as xs:string, 
        $consumer-secret as xs:string, 
        $access-token as xs:string, 
        $access-token-secret as xs:string, 
        $user-id as xs:string?,
        $screen-name as xs:string?,
        $since-id as xs:unsignedLong?, (: IDs are too big for xs:integer :)
        $count as xs:integer?,
        $max-id as xs:unsignedLong?,
        $trim-user as xs:boolean?,
        $exclude-replies as xs:boolean?,
        $contributor-details as xs:boolean?,
        $include-rts as xs:boolean? 
        ) {
    let $api-method := '/statuses/user_timeline.json'
    let $http-method := 'GET'
    let $query-string := 
        string-join(
            (
            "tweet_mode=extended",
            if ($user-id) then concat('user_id=', $user-id) else (),
            if ($screen-name) then concat('screen_name=', $screen-name) else (),
            if ($since-id) then concat('since_id=', $since-id) else (),
            if ($count) then concat('count=', $count) else (),
            if ($max-id) then concat('max_id=', $max-id) else (),
            if ($trim-user) then concat('trim_user=', $trim-user) else (),
            if ($exclude-replies) then concat('exclude_replies=', $exclude-replies) else (),
            if ($contributor-details) then concat('contributor_details=', $contributor-details) else (),
            if ($include-rts) then concat('include_rts=', $include-rts) else ()
            ),
            '&amp;'
        )
    let $api-url := concat($twitter:api-base-uri, $api-method, '?', $query-string)
    return
        oauth:send-request(
            $consumer-key, 
            $consumer-secret,
            $access-token,
            $access-token-secret,
            $http-method,
            $api-url,
            oauth:nonce(),
            $oauth:signature-method, 
            oauth:timestamp(), 
            $oauth:oauth-version
        )
};

(:
    Show a tweet.
    See https://dev.twitter.com/docs/api/1.1/get/statuses/show
:)
declare function twitter:show(
        $consumer-key as xs:string, 
        $consumer-secret as xs:string, 
        $access-token as xs:string, 
        $access-token-secret as xs:string, 
        $id as xs:unsignedLong,
        $trim-user as xs:boolean?,
        $include-my-retweet as xs:boolean?,
        $include-entities as xs:boolean?
        ) {
    let $api-method := '/statuses/show.json'
    let $http-method := 'GET'
    let $query-string := 
        string-join(
            (
            concat('id=', $id),
            "tweet_mode=extended",
            if ($trim-user) then concat('trim_user=', $trim-user) else (),
            if ($include-my-retweet) then concat('include_my_retweet=', $include-my-retweet) else (),
            if ($include-entities) then concat('include_entities=', $include-entities) else ()
            ),
            '&amp;'
        )
    let $api-url := concat($twitter:api-base-uri, $api-method, '?', $query-string)
    return
        oauth:send-request(
            $consumer-key, 
            $consumer-secret,
            $access-token,
            $access-token-secret,
            $http-method,
            $api-url,
            oauth:nonce(),
            $oauth:signature-method, 
            oauth:timestamp(), 
            $oauth:oauth-version
        )
};

declare function twitter:echo-response($request-response as item()+) {
    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $json := parse-json(util:binary-to-string($response-body))
    return 
        (
            $request, 
            $response-head, 
            serialize($json, map { "method": "json", "indent": true() } )
        )
};