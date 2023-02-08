xquery version "3.1";

let $json := json-doc('/db/apps/twitter/user-timeline.json')
for $tweet in $json?*
return $tweet?entities?*