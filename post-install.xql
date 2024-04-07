xquery version "3.0";

import module namespace dbutil="http://exist-db.org/xquery/dbutil" at "modules/dbutil.xqm";
import module namespace sm="http://exist-db.org/xquery/securitymanager";

(: Specific to this app: :)
import module namespace secrets="http://history.state.gov/ns/xquery/twitter/secrets" at 'modules/twitter-secrets.xqm';


(: Specific to this app: :)
let $users :=
    <users>
        <user>
            <username>twitter-agent</username>
            <password>{secrets:read-secret('twitter-agent-password')}</password>
            <full-name>Twitter Agent</full-name>
            <description>User account for Twitter polling jobs</description>
            <group>twitter-agents</group>
        </user>
    </users>
let $groups :=
    <groups>
        <group>
            <name>twitter-agents</name>
            <description>Group for Twitter agent accounts</description>
        </group>
    </groups>

let $resources :=
    <resources>
        <resource>
            <path>/db/apps/twitter/jobs/download-recent-twitter-json.xq</path>
            <type>file</type>
            <owner>twitter-agent:twitter-agents</owner>
            <mode>rwsr-sr-x</mode>
        </resource>
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

let $create-users := 
    for $user in $users/user
    let $user-groups := $groups/group[name = $user/group]
    let $create-groups := 
        for $group in $user-groups
        let $group-name := $group/name
        let $group-description := $group/description
        return 
            if (sm:group-exists($group-name)) then 
                concat('group "', $group-name, '" already exists') 
            else 
                (
                sm:create-group($group-name, $group-description)
                ,
                concat('created group "', $group-name, '"')
                )
    let $username := $user/username
    let $create-user := 
        if (sm:user-exists($username)) then 
            concat('user "', $username, '" already exists') 
        else 
            let $password := $user/password
            let $groups := $user/group
            let $full-name := $user/full-name
            let $user-description := $user/description
            (: see #17 :)
            return
                (
                sm:create-account($username, $password, $groups, $full-name, $user-description)
                ,
                concat('created user "', $username, '"')
                )
    return ($create-groups, $create-user)

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
    <result>{($create-users, $set-resource-permissions)}</result>
