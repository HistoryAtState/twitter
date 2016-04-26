xquery version "3.1";

module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader";

(:~ A library module with functions for downloading/crawling Twitter.
:)

import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";
import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace pt = "http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";

declare variable $twitter-dl:data-collection := '/db/apps/twitter/data';
declare variable $twitter-dl:import-collection := '/db/apps/twitter/import';
declare variable $twitter-dl:logs-collection := '/db/apps/twitter/import-logs';


declare function twitter-dl:crawl-user-timeline($count as xs:integer, $max-id as xs:unsignedLong?) {
    let $request-response := twitter:user-timeline(
        config:consumer-key(), config:consumer-secret(), config:access-token(), config:access-token-secret(),
        (), (), (), $count, $max-id, true(), true(), false(), false())

    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $json := parse-json(util:binary-to-string($response-body))
    return <results> {
    for $tweet in $json?*
        let $tweet-xml := pt:tweet-json-to-xml($tweet, 'HistoryAtState')
        let $store := pt:store-tweet-xml($tweet-xml)
        return <stored tweet-id="{$tweet-xml/id}" tweet-date="{$tweet-xml/date}" />
    } </results>
};

