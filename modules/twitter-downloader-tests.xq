xquery version "3.1";

import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";
import module namespace twitter="http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader" at "twitter-downloader.xqm";
import module namespace pt = "http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";

declare namespace here = "http://history.state.gov/ns/xquery/twitter/twitter-downloader-tests";

declare function here:download-raw($count as xs:unsignedInt?, $max-id as xs:unsignedLong?) {
    let $count := if($count) then $count else 1
    let $request-response := twitter:user-timeline(
        config:consumer-key(), config:consumer-secret(), config:access-token(), config:access-token-secret(),
        (), (), (), $count, $max-id, true(), true(), false(), false())

    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $response-body-text := util:binary-to-string($response-body)
    let $json := parse-json($response-body-text)
    return
        <result>
            <head>
                {$response-head}
            </head>
            <raw-body>
                {$response-body}
            </raw-body>
            <body>
                {$response-body-text}
            </body>
            <xml>{
                for $tweet in $json?*
                let $tweet-xml := pt:tweet-json-to-xml($tweet, 'HistoryAtState')
                return $tweet-xml
            } </xml>
    </result>
};


(:twitter-dl:download-last-posts(10, ()):)
(:twitter-dl:download-last-posts(30, 720271125960204289):)

twitter-dl:download-all-last-posts()

(:twitter-dl:download-last-json(()):)
(:twitter-dl:download-all-last-json():)

(:here:download-raw(5, ()):)
