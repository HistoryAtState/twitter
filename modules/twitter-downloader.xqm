xquery version "3.1";

module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader";

(:~ A library module with functions for downloading/crawling Twitter.
:)

declare function twitter-client:crawl-user-timeline($count as xs:integer, $max-id as xs:unsignedLong?) {
    let $response := twitter:user-timeline($twitter-client:consumer-key, $twitter-client:consumer-secret, $twitter-client:access-token, $twitter-client:access-token-secret, (), (), (), $count, $max-id, true(), true(), false(), false())
    let $result := twitter-client:process-response($response)
    return 
        (
        $result
        ,
        if (xs:integer($result/records-stored) = 0) then 
            (
            <result>done - no more tweets to crawl</result>
            ,
            if (doc-available(concat($twitter-client:logs-collection, '/crawl-user-timeline-state.xml'))) then xmldb:remove($twitter-client:logs-collection, 'crawl-user-timeline-state.xml') else ()
            ,
            xmldb:store($twitter-client:logs-collection, 'last-crawl.xml', <last-crawl><datetime>{util:system-dateTime()}</datetime></last-crawl>)
            )
        else
            (
            xmldb:store($twitter-client:logs-collection, 'crawl-user-timeline-state.xml', $result)
            ,
            if (xs:integer($result/x-rate-limit-remaining) gt 1 or current-dateTime() gt xs:dateTime($result/x-rate-limit-datetime)) then
                let $new-max-id := xs:unsignedLong($result/min-id) - 1
                return
                    twitter-client:crawl-user-timeline($count, $new-max-id)
            else 
                <result>wait until {$result/x-rate-limit-datetime} to proceed with crawl</result>
            )
        )
};

