xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace dbutil="http://exist-db.org/xquery/dbutil";

(: Specific to this app: :)
let $resources :=
    <resources>
        <resource>
            <path>/db/apps/twitter/jobs/download-recent-twitter-posts.xq</path>
            <type>file</type>
            <owner>twitter-agent:twitter-agents</owner>
            <mode>rwsr-sr-x</mode>
        </resource>
        <resource>
            <path>/db/apps/twitter/data</path>
            <type>collection</type>
            <owner>twitter-agent:twitter-agents</owner>
            <mode>rwxrwsr-x</mode>
        </resource>
        <resource>
            <path>/db/apps/twitter/data/HistoryAtState</path>
            <type>collection</type>
            <owner>twitter-agent:twitter-agents</owner>
            <mode>rwxrwsr-x</mode>
        </resource>
        <resource>
            <path>/db/apps/twitter/import</path>
            <type>collection</type>
            <owner>twitter-agent:twitter-agents</owner>
            <mode>rwxrwsr-x</mode>
        </resource>
    </resources>
let $set-resource-permissions := 
    for $resource in $resources/resource
    let $type := $resource/type
    let $path := xs:anyURI($resource/path)
    let $mode := $resource/mode
    let $owner := $resource/owner
    return
        if ($type = 'file') then
            let $chown := sm:chown($path, $owner)
            let $chmod := sm:chmod($path, $mode) 
            return
                concat('set "', $path, '" to be owned by "', $owner, '" and to have permissions "', $mode, '"')
        else (: if ($type = 'collection' then :)
            dbutil:scan(
                $path
                ,
                function($a-collection, $a-resource) { 
                    if ($a-resource) then 
                        let $chown := sm:chown($a-resource, $owner)
                        let $chmod := sm:chmod($a-resource, 'rw-r--r--') 
                        return
                            concat('set "', $a-resource, '" to be owned by "', $owner, '" and to have default permissions')
                    else
                        let $chown := sm:chown($a-collection, $owner)
                        let $chmod := sm:chmod($a-collection, $mode)
                        return
                            concat('set "', $a-collection, '" to be owned by "', $owner, '" and to have permissions "', $mode, '"')
                    }
            )
return
    ($set-resource-permissions)