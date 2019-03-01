xquery version "3.1";

(: Can be configured as a job, or started manually. :)

import module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader" at "/db/apps/twitter/modules/twitter-downloader.xqm";

import module namespace secrets="http://history.state.gov/ns/xquery/twitter/secrets" at "/db/apps/twitter/modules/twitter-secrets.xqm";

declare function local:download-tweets() {


    let $log-start := util:log-system-out(concat('Starting Twitter (JSON) check at ', current-dateTime()))
    let $start-time := util:system-time()
    let $report :=
        twitter-dl:download-all-last-json()

    let $end-time := util:system-time()
    let $runtimems := (($end-time - $start-time) div xs:dayTimeDuration('PT1S'))  * 1000
    let $log-end := util:log-system-out(concat('Finished Twitter check at :', current-dateTime()))
    let $log-size := util:log-system-out(concat('Stored ', count($report/stored), ' new posts from Twitter (JSON).'))
    let $log-runtime := util:log-system-out(concat('Twitter check in milliseconds: ', $runtimems))

    return
    <results>
       <message>Completed operation in {$runtimems} ms</message>
       {$report}
    </results>

};

system:as-user("twitter-agent", secrets:read-secret('twitter-agent-password'), local:download-tweets())