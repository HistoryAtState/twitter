xquery version "3.1";

(: Run the Twitter Update function.  Should be run every 5 minutes.
   $EXIST_HOME/conf.xml may contain a relevant Job Scheduler Entry like this:
   <job xquery="/db/apps/twitter/jobs/download-recent-twitter-posts.xq"  period="300000"/>
:)

import module namespace twitter-dl="http://history.state.gov/ns/xquery/twitter-downloader" at "../modules/twitter-downloader.xqm";


let $log-start := util:log-system-out(concat('Starting Twitter check at ', current-dateTime()))
let $start-time := util:system-time()
let $report := 
    twitter-dl:download-all-last-posts()

let $end-time := util:system-time()
let $runtimems := (($end-time - $start-time) div xs:dayTimeDuration('PT1S'))  * 1000
let $log-size := util:log-system-out(concat('Stored ', count($report/stored), ' new posts from Twitter at :', current-dateTime(), ' (in ', $runtimems, 'ms)' ))
let $_ := util:log-app('info', 'hsg-twitter', concat('Stored ', count($report/stored), ' new posts from Twitter (in ', $runtimems, 'ms)' ))

return
    
<results>
   <message>Completed operation in {$runtimems} ms</message>
   {$report}
</results>

