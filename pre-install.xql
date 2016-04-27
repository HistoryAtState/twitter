xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};


(: Default task: store the collection configuration :)
local:mkcol("/db/system/config", $target),
xdb:store-files-from-pattern(concat("/system/config", $target), $dir, "*.xconf"),

(: Specific to this app: :)
let $users :=
    <users>
        <user>
            <username>twitter-agent</username>
            <password>h29Da]Zuz^ubg9vyjY[x</password>
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
            return
                (
                sm:create-account($username, $password, $groups, $full-name, $user-description)
                ,
                concat('created user "', $username, '"')
                )
    return ($create-groups, $create-user)
return
    ($create-users)