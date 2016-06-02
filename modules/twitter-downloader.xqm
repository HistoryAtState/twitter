xquery version "3.1";

module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader";

(:~ A library module with functions for downloading/crawling Twitter.
:)

import module namespace config = "http://history.state.gov/ns/xquery/twitter/config" at "config.xqm";
import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";
import module namespace pt = "http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";
declare namespace hc = "http://expath.org/ns/http-client";
declare namespace util = "http://exist-db.org/xquery/util";

declare function twitter-dl:copy-header-to-attribute($response-head as node()?, $name as xs:string) as attribute()? {
    let $content := string($response-head//hc:header[@name=$name]/@value)
    return if($content)
    then attribute {$name} {$content}
    else ()
};

(: An inefficient way to check if a file is present in a collection.
 :)
declare function twitter-dl:is-file-present($collection as xs:string, $file as xs:string) as xs:boolean {
        let $all-files := xmldb:get-child-resources($collection)
        return $file = $all-files
};


(: Downloads to the local store a portion of tweets from the configured user timeline.
 : $count - the number of tweets to obtain; if not given, it is read from config
 : $max-id - recent tweets before this one (including this one if such exists) will be downloaded; if not given, most recent tweets will be downloaded.
 : Returns an XML summary of downloaded tweets, including all downloaded tweet ids (from the earliest to the oldest).
 : report/stored describes a tweet which has been stored to the database, and report/existed a tweet which already existed and has been skipped.
 :)
declare function twitter-dl:download-last-posts($count as xs:integer?, $max-id as xs:unsignedLong?) {
    let $count := if($count > 0) then $count else $config:download-chunk-size
    let $_ := util:log-app('info', 'hsg-twitter', 'Sending Twitter request, count=' || $count || ', maxid=' || $max-id)
    let $request-response := twitter:user-timeline(
        config:consumer-key(), config:consumer-secret(), config:access-token(), config:access-token-secret(),
        (), (), (), $count, $max-id, true(), true(), false(), false())

    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $json := parse-json(util:binary-to-string($response-body))
    let $_ := util:log-app('info', 'hsg-twitter', 'Twitter response, count=' || count($json?*)
                || ', x-rate-limit-remaining=' || $response-head//hc:header[@name='x-rate-limit-remaining']/@value)
    return <report requested-count="{$count}"> {
        twitter-dl:copy-header-to-attribute($response-head, 'x-rate-limit-limit'),
        twitter-dl:copy-header-to-attribute($response-head, 'x-rate-limit-remaining'),
        twitter-dl:copy-header-to-attribute($response-head, 'x-rate-limit-datetime'),
        if($max-id)
            then attribute requested-max-id {$max-id}
            else (),
        for $tweet in $json?*
            let $tweet-xml := pt:tweet-json-to-xml($tweet, 'HistoryAtState')
            let $path-to-store := pt:full-path-for-tweet($tweet-xml)
            return if (doc-available($path-to-store))
            then
                let $_ := util:log-app('debug', 'hsg-twitter', 'Twitter post (XML) already found, id=' || $tweet-xml/id)
                return <existed tweet-id="{$tweet-xml/id}" tweet-date="{$tweet-xml/date}" />
            else
                let $_ := util:log-app('info', 'hsg-twitter', 'Storing Twitter post (XML), id=' || $tweet-xml/id)
                let $store := pt:store-tweet-xml($tweet-xml)
                return <stored tweet-id="{$tweet-xml/id}" tweet-date="{$tweet-xml/date}" />
    } </report>
};

(: Recursive function to download tweets until we match an already downloaded one (or no more tweets on the server).
 :)
declare function twitter-dl:download-last-posts-rec($max-id as xs:unsignedLong?, $report-accumulator as node()) {
    let $this-time-report := twitter-dl:download-last-posts((), $max-id)
    let $next-id-to-check := min($this-time-report/stored/@tweet-id ! xs:unsignedLong(.)) - 1
    let $suspend :=
        if ($this-time-report/@x-rate-limit-remaining <= 4)
        then attribute suspended {$next-id-to-check}
        else ()
    let $acc := <report> {
        $suspend,
        $report-accumulator/*,
        $this-time-report/*
    }</report>
    return
    if($suspend)
    then
        let $_ := util:log-app('info', 'hsg-twitter', 'Twitter download SUSPENDING due to x-rate limit reached, id=' || $next-id-to-check || ', downloaded so far: ' || count($acc/*))
        return $acc
    else if(count($this-time-report/stored) = 0 or $this-time-report/existed)
    then
        let $_ := util:log-app('info', 'hsg-twitter', 'Twitter download loop FINISHES at id=' || $next-id-to-check || ', downloaded: ' || count($acc/*))
        return $acc
    else
        let $_ := util:log-app('info', 'hsg-twitter', 'Twitter download loop CONTINUES at id=' || $next-id-to-check || ', downloaded so far: ' || count($acc/*))
        return twitter-dl:download-last-posts-rec($next-id-to-check, $acc)
};

(: Downloads to the local store all recent tweets from the configured user timeline.
 : Returs an XML summary of downloaded tweets, a concatenation of twitter-dl:download-last-posts reports.
 :)
declare function twitter-dl:download-all-last-posts() {
    let $twitter-state-file := $config:data-collection || '/' || $config:twitter-state-file-name
    let $twitter-state :=
        if(doc-available($twitter-state-file))
        then
            doc($twitter-state-file)/twitter-state
        else
            <twitter-state>
            </twitter-state>
    let $starting-max-id := $twitter-state/xml/suspended/text()
    let $report := twitter-dl:download-last-posts-rec($starting-max-id, <report/>)
    let $final-twitter-state :=
        <twitter-state>
            <xml>
                <max-known-id>{max(($twitter-state/xml/max-known-id, $report/stored/@tweet-id, $report/existed/@tweet-id) ! xs:unsignedLong(.))}</max-known-id>
                {
                if($report/@suspended)
                then <suspended>{string($report/@suspended)}</suspended>
                else ()
                }
            </xml>
        </twitter-state>
    let $store-state := xmldb:store($config:data-collection, $config:twitter-state-file-name, $final-twitter-state)
    return $report

};


(: Downloads raw JSON data of a recent tweet to the import directory.
 : $max-id - recent tweets before this one (including this one if such exists) will be downloaded; if not given, most recent tweets will be downloaded.
 : Returns an XML summary of downloaded tweets, including all downloaded tweet ids (from the earliest to the oldest).
 : report/stored describes a tweet which has been stored to the database, and report/existed a tweet which already existed and has been skipped.
 :)
declare function twitter-dl:download-last-json($max-id as xs:unsignedLong?) {
    let $_ := util:log-app('info', 'hsg-twitter', 'Sending Twitter request1 , maxid=' || $max-id)
    let $request-response := twitter:user-timeline(
        config:consumer-key(), config:consumer-secret(), config:access-token(), config:access-token-secret(),
        (), (), (), 1, $max-id, true(), true(), false(), false())

    let $request := $request-response[1]
    let $response-head := $request-response[2]
    let $response-body := $request-response[3]
    let $response-body-text := util:binary-to-string($response-body)
    let $json := parse-json($response-body-text)
    let $tweet := ($json?*)[1]
    let $tweet-id := xs:unsignedLong($tweet?id_str)
    let $file-name :=  $tweet-id || '.json'
    return
        <report> {
        if (twitter-dl:is-file-present($config:import-collection, $file-name))
        then
            let $_ := util:log-app('debug', 'hsg-twitter', 'Twitter post (JSON) already found, id=' || $tweet-id)
            return <existed tweet-id="{$tweet-id}" created_at="{$tweet?created_at}" />
        else
            let $_ := util:log-app('info', 'hsg-twitter', 'Storing Twitter post (JSON), id=' || $tweet-id)
            let $store := xmldb:store-as-binary($config:import-collection, $file-name, $response-body-text)
            return <stored tweet-id="{$tweet-id}" created_at="{$tweet?created_at}" />
        } </report>
};

declare function twitter-dl:download-last-json-rec($max-id as xs:unsignedLong?, $report-accumulator as node()) {
    let $this-time-report := twitter-dl:download-last-json($max-id)
    let $acc := <report> {
        $report-accumulator/*,
        $this-time-report/*
    }</report>
    return
    if(count($this-time-report/stored) = 0 or $this-time-report/existed)
    then $acc
    else
        let $id-to-check := min($this-time-report/stored/@tweet-id ! xs:unsignedLong(.)) - 1
        return twitter-dl:download-last-json-rec($id-to-check, $acc)
};

(: Downloads to the local store JSON version of all recent tweets from the configured user timeline.
 : Returs an XML summary of downloaded tweets, a concatenation of twitter-dl:download-last-json reports.
 :)
declare function twitter-dl:download-all-last-json() {
    twitter-dl:download-last-json-rec((), <report/>)
};
