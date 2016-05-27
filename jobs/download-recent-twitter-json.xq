xquery version "3.1";

import module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader" at "../modules/twitter-downloader.xqm";


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

