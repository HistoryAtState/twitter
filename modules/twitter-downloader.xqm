xquery version "3.1";

module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader";

(:~ A library module with functions for downloading/crawling Twitter.
:)

import module namespace twitter = "http://history.state.gov/ns/xquery/twitter" at "twitter.xqm";

declare variable $twitter-dl:data-collection := '/db/apps/twitter/data';
declare variable $twitter-dl:import-collection := '/db/apps/twitter/import';
declare variable $twitter-dl:logs-collection := '/db/apps/twitter/import-logs';


declare function twitter-dl:crawl-user-timeline($count as xs:integer, $max-id as xs:unsignedLong?) {
    let $consumer-key := ''
    let $consumer-secret :=''
    let $access-token := ''
    let $access-token-secret := ''
    
    let $response := twitter:user-timeline($consumer-key, $consumer-secret, $access-token, $access-token-secret, (), (), (), $count, $max-id, true(), true(), false(), false())

    let $result := twitter-dl:process-response($response)
    return 
        (
        $result
        ,
        if (xs:integer($result/records-stored) = 0) then 
            (
            <result>done - no more tweets to crawl</result>
            ,
            if (doc-available(concat($twitter-dl:logs-collection, '/crawl-user-timeline-state.xml'))) then xmldb:remove($twitter-dl:logs-collection, 'crawl-user-timeline-state.xml') else ()
            ,
            xmldb:store($twitter-dl:logs-collection, 'last-crawl.xml', <last-crawl><datetime>{util:system-dateTime()}</datetime></last-crawl>)
            )
        else
            (
            xmldb:store($twitter-dl:logs-collection, 'crawl-user-timeline-state.xml', $result)
            ,
            if (xs:integer($result/x-rate-limit-remaining) gt 1 or current-dateTime() gt xs:dateTime($result/x-rate-limit-datetime)) then
                let $new-max-id := xs:unsignedLong($result/min-id) - 1
                return
                    twitter-dl:crawl-user-timeline($count, $new-max-id)
            else 
                <result>wait until {$result/x-rate-limit-datetime} to proceed with crawl</result>
            )
        )
};
