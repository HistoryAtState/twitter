xquery version "3.1";

import module namespace ju = "http://joewiz.org/ns/xquery/json-util" at "/db/apps/twitter/json-util.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "/db/apps/twitter/date-parser.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace functx="http://www.functx.com";

(: for info about each entity type see https://dev.twitter.com/overview/api/entities-in-twitter-objects :)

(: chops a string of text into the bits surrounding an entity :)
declare function local:chop($text as xs:string, $indices as array(*)) {
    let $index-start := $indices?1
    let $index-end := $indices?2
    let $before := substring($text, 1, $index-start)
    let $after := substring($text, $index-end + 1)
    let $entity := substring($text, $index-start + 1, $index-end - $index-start)
    return
        (
(:        console:log('chopped text into: before: "' || $before || '" entity: "' || $entity || '" after: "' || $after || '"'), :)
        $before, $entity, $after
        )
};

(: https://dev.twitter.com/overview/api/entities-in-twitter-objects#urls :)
declare function local:url($text as xs:string, $url-map as map(*)) {
    let $chunks := local:chop($text, $url-map?indices)
    let $text := $url-map?display_url
    let $url := $url-map?expanded_url
    return
        ($chunks[1], <a href="{$url}">{$text}</a>, $chunks[3])
};

(: https://dev.twitter.com/overview/api/entities-in-twitter-objects#hashtags :)
declare function local:hashtag($text as xs:string, $hashtag-map as map(*)) {
    let $chunks := local:chop($text, $hashtag-map?indices)
    let $text := $hashtag-map?text
    let $url := concat('https://twitter.com/search?q=%23', $text, '&amp;src=hash')
    return
        ($chunks[1], <a href="{$url}">#{$text}</a>, $chunks[3])
};

(: https://dev.twitter.com/overview/api/entities-in-twitter-objects#user_mentions :)
declare function local:user-mention($text as xs:string, $user-mention-map as map(*)) {
    let $chunks := local:chop($text, $user-mention-map?indices)
    let $text := $user-mention-map?screen_name
    let $url := concat('https://twitter.com/', $text)
    return
        ($chunks[1], <a href="{$url}">@{$text}</a>, $chunks[3])
};

(: apply entities, from last to first; entities must already be in last-to-first order :)
declare function local:apply-entities($text as xs:string, $entities as map(*)*, $segments as item()*) {
    if (empty($entities)) then 
        ($text, $segments)
    else
        let $entity := head($entities)
        let $type := $entity?type
        let $results := 
            if ($type = 'url') then
                local:url($text, $entity)
            else if ($type = 'hashtag') then
                local:hashtag($text, $entity)
            else (: if ($type = 'user-mention') then :)
                local:user-mention($text, $entity)
        let $remaining-text := subsequence($results, 1, 1)
        let $remaining-entities := tail($entities)
        let $completed-segments := (subsequence($results, 2), $segments)
        return
            local:apply-entities($remaining-text, $remaining-entities, $completed-segments)
};

(: sift through the entities and get them into the right order for processing last-to-first.
 : tweet entities are grouped by type, and they do not come in any order with relation to the text,
 : so we need to sort them first before applying them :)
declare function local:process-entities($tweet as map(*)) {
    let $text := $tweet?text
    let $entities-map := map:get($tweet, 'entities')
    let $entities-to-process :=
        for $entity-key in map:keys($entities-map)
        let $entity := map:get($entities-map, $entity-key)
        return 
            (: drop empty entity arrays :)
            if (array:size($entity) gt 0) then
                switch ($entity-key) 
                    case 'urls' return
                        for $e in $entity?*
                        return
                            map:new(( map {'type': 'url'}, $e ))
                    case 'hashtags' return
                        for $e in $entity?*
                        return
                            map:new(( map {'type': 'hashtag'}, $e ))
                    case 'user_mentions' return
                        for $e in $entity?*
                        return
                            map:new(( map {'type': 'user-mention'}, $e ))
                    default return 
                        (: drop all other entities; we won't process these others.
                         : note that any included entites need an "indices" array :)
                        ()
            else 
                ()
    let $ordered-entities :=
        (: sort by end position of each entity, so we process them from last to first :)
        for $entity in $entities-to-process
        order by $entity?indices?2 descending
        return $entity
    return
        local:apply-entities($text, $ordered-entities, ())
};

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function local:tweet-json-to-xml($tweet) {
    let $id := xs:decimal($tweet?id)
    let $url := concat('https://twitter.com/HistoryAtState/statuses/', $id)
    let $text := $tweet?text
    let $created-at := $tweet?created_at
    let $created-datetime := adjust-dateTime-to-timezone(xs:dateTime(dates:parseDateTime(replace($created-at, '\+0000 (\d{4})', '$1 0000'))), ())
    return
        <tweet>
            <date>{$created-datetime}</date>
            <id>{$id}</id>
            <url>{$url}</url>
            <text>{$text}</text>
            <html>{local:process-entities($tweet)}</html>
        </tweet>
};

declare function local:store-tweet-xml($tweet-xml) {
    let $created-datetime := xs:dateTime($tweet/created-datetime)
    let $year := year-from-date($created-datetime)
    let $month := functx:pad-integer-to-length(month-from-date($created-datetime), 2)
    let $day := functx:pad-integer-to-length(day-from-date($created-datetime), 2)
    let $destination-col := string-join(('/db/apps/twitter/data', $year, $month, $day), '/')
    let $filename := concat($id, '.xml')
    return
        (
            if (xmldb:collection-available($destination-col)) then () else local:mkcol-recursive('/db/apps/twitter/data', ($year, $month, $day)),
            xmldb:store($destination-col, $filename, $tweet)
        )
};

let $import-col := '/db/apps/twitter/import'
let $files := xmldb:get-child-resources($import-col)
let $paths := $files ! concat($import-col, '/', .)
for $path in $paths
let $json := json-doc($path)
for $tweet in $json?*
let $tweet-xml := local:tweet-json-to-xml($tweet)
return $tweet-xml