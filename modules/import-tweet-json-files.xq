xquery version "3.1";

(: import tweets stored as .json files in import collection :)

import module namespace pt="http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";

let $import-col := '/db/apps/twitter/import'
let $files := xmldb:get-child-resources($import-col)
let $paths := $files ! concat($import-col, '/', .)
for $path in $paths
let $json := json-doc($path)
for $tweet in $json?*
let $tweet-xml := pt:tweet-json-to-xml($tweet, 'HistoryAtState')
return 
    pt:store-tweet-xml($tweet-xml)