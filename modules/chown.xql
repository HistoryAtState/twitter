xquery version "3.1";

(: Script to set all permissions of a specified collection to a specified user:)

declare function local:chmod($path as xs:string, $user as xs:string){    
    element col {
        attribute path { $path },
        let $resources :=
            for $res in xmldb:get-child-resources($path)
                let $chown := sm:chown(xs:anyURI($path || "/" || $res), $user)
                return
                    <res>{$res}</res>
        let $cols :=
            for $col in xmldb:get-child-collections($path)
                let $chown := sm:chown(xs:anyURI($path || "/" || $col), $user)
                return
                    local:chmod($path || "/" || $col, $user)

        return
            (
            $resources,
            $cols
            )
    }
};

let $root := "/db/apps/twitter/data"
return
    element result {
        local:chmod($root,"twitter-agent")
    }
