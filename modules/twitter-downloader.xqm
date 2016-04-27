xquery version "3.1";

module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader";

(:~ A library module with functions for downloading/crawling Twitter.
:)

import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";
import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace pt = "http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";

declare variable $twitter-dl:data-collection := '/db/apps/twitter/data';
declare variable $twitter-dl:import-collection := '/db/apps/twitter/import';

(: Downloads to the local store a portion of tweets from the configured user timeline.
 : $count - the number of tweets to obtain; if not given, it is read from config
 : $max-id - recent tweets before this one (including this one if such exists) will be downloaded; if not given, most recent tweets will be downloaded.
 : Returns an XML summary of downloaded tweets, including all downloaded tweet ids (from the earliest to the oldest).
 : report/stored describes a tweet which has been stored to the database, and report/existed a tweet which already existed and has been skipped.
 :)
declare function twitter-dl:download-last-posts($count as xs:integer?, $max-id as xs:unsignedLong?) {
    let $count := if($count > 0) then $count else $config:download-chunk-size
    let $request-response := twitter:user-timeline(
        config:consumer-key(), config:consumer-secret(), config:access-token(), config:access-token-secret(),
        (), (), (), $count, $max-id, true(), true(), false(), false())

    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $json := parse-json(util:binary-to-string($response-body))
    return <report requested-count="{$count}"> {
        if($max-id)
            then attribute requested-max-id {$max-id}
            else (),
        for $tweet in $json?*
            let $tweet-xml := pt:tweet-json-to-xml($tweet, 'HistoryAtState')
            let $path-to-store := pt:full-path-for-tweet($tweet-xml)
            return if (doc-available($path-to-store))
            then <existed tweet-id="{$tweet-xml/id}" tweet-date="{$tweet-xml/date}" />
            else
                let $store := pt:store-tweet-xml($tweet-xml)
                return <stored tweet-id="{$tweet-xml/id}" tweet-date="{$tweet-xml/date}" />
    } </report>
};

(: Recursive function to download tweets until we match an already downloaded one (or no more tweets on the server).
 :)
(: TODO? Support XRate headers and stop when limit reached. :)
declare function twitter-dl:download-last-posts-rec($max-id as xs:unsignedLong?, $report-accumulator as node()) {
    let $this-time-report := twitter-dl:download-last-posts((), $max-id)
    let $acc := <report> {
        $report-accumulator/*,
        $this-time-report/*
    }</report>
    return
    if(count($this-time-report/stored) = 0 or $this-time-report/existed)
    then $acc
    else
        let $id-to-check := min($this-time-report/stored/@tweet-id ! xs:unsignedLong(.)) - 1
        return twitter-dl:download-last-posts-rec($id-to-check, $acc)
};

(: Downloads to the local store all recent tweets from the configured user timeline.
 : Returs an XML summary of downloaded tweets, a concatenation of twitter-dl:download-last-posts reports.
 :)
declare function twitter-dl:download-all-last-posts() {
    twitter-dl:download-last-posts-rec((), <report/>) 
};

