xquery version "3.1";

(: import tweets stored as .json files in import collection :)

import module namespace pt="http://history.state.gov/ns/xquery/twitter/process-tweets" at "process-tweets.xqm";
import module namespace ju = "http://joewiz.org/ns/xquery/json-util" at "json-util.xqm";

let $json := json-doc('/db/apps/twitter/import/621391235337592833.json')
let $tweets := $json?*
for $tweet in $tweets[?id = 621391235337592833]
return
    (
(:        ju:serialize-json($tweet),:)
    pt:tweet-json-to-xml($tweet, 'HistoryAtState')
    )