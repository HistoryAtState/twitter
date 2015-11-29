xquery version "3.1";

import module namespace ju = "http://joewiz.org/ns/xquery/json-util" at "/db/apps/twitter/modules/json-util.xqm";

let $json := json-doc('/db/apps/twitter/user-timeline.json')
for $tweet in $json?*
return $tweet?entities?* ! ju:advise(.)