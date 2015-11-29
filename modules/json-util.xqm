xquery version "3.1";

(: Utility functions for JSON in XQuery 3.1.
 : See http://www.w3.org/TR/xpath-functions-31/#json :)

module namespace ju = "http://joewiz.org/ns/xquery/json-util";

declare namespace json = "http://www.w3.org/2013/XSL/json";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(: Get the data type for a piece of JSON data :)
declare function ju:json-data-type($json) {
    if ($json instance of array(*)) then 'array'
    else if ($json instance of map(*)) then 'map'
    else if ($json instance of xs:string) then 'string'
    else if ($json instance of xs:double) then 'number'
    else if ($json instance of xs:boolean) then 'boolean'
    else if (empty($json)) then 'null'
    else error(xs:QName('ERR'), 'Not a known data type for json data')
};

(: Transform JSON into intermediate XML format described at http://www.w3.org/TR/xslt-30/#json :)
declare function ju:json-to-xml($json) {
    let $data-type := ju:json-data-type($json)
    return
        element {QName('http://www.w3.org/2013/XSL/json', $data-type)} {
            if ($data-type = 'array') then
                for $array-member in $json?*
                let $array-member-data-type := ju:json-data-type($array-member)
                return 
                    element {$array-member-data-type} {
                        if ($array-member-data-type = ('map', 'array')) then 
                            ju:json-to-xml($array-member)/node() 
                        else 
                            $array-member
                    }
            else if ($data-type = 'map') then
                map:for-each-entry(
                    $json, 
                    function($object-name, $object-value) {
                        let $object-value-data-type := ju:json-data-type($object-value)
                        return 
                            element {QName('http://www.w3.org/2013/XSL/json', $object-value-data-type)} {
                                attribute key {$object-name}, 
                                if ($object-value-data-type = ('map', 'array')) then 
                                    ju:json-to-xml($object-value)/node() 
                                else 
                                    $object-value
                            }
                    }
                )
            else (: if ($type = ('string', 'number', 'boolean', 'null')) then :)
                $json
        }
};

(: Transform intermediate XML format into JSON; see http://www.w3.org/TR/xslt-30/#func-xml-to-json :)
declare function ju:xml-to-json($nodes) {
    for $node in $nodes
    return
        typeswitch ($node)
            case element(json:map) return
                if ($node/@key) then
                    map { $node/@key := ju:xml-to-json($node/node()) }
                else
                    map:new( ju:xml-to-json($node/node()) )
            case element(json:array) return
                if ($node/@key) then
                    map { $node/@key := array { ju:xml-to-json($node/node()) } }
                else
                    array { ju:xml-to-json($node/node()) }
            case element(json:string) return
                if ($node/@key) then 
                    map { $node/@key := $node/string() }
                else 
                    $node/string()
            case element(json:number) return
                if ($node/@key) then
                    map { $node/@key := $node cast as xs:double }
                else 
                    $node cast as xs:double
            case element(json:boolean) return
                if ($node/@key) then 
                    map { $node/@key := $node cast as xs:boolean }
                else
                    $node cast as xs:boolean
            case element(json:null) return
                if ($node/@key) then 
                    map { $node/@key := () }
                else
                    ()
            case text() return 
                $node
            default return
                error(xs:QName('ERR'), 'Does not match known node types for xml-to-json data')
};

(: Serialize with indentation :)
declare function ju:serialize-json($json) {
    let $serialization-parameters := 
        <output:serialization-parameters>
            <output:method>json</output:method>
            <output:indent>yes</output:indent>
        </output:serialization-parameters>
    return
        serialize($json, $serialization-parameters)
};

declare function ju:advise($json as item()) {
    let $type := try { ju:json-data-type($json) } catch * { concat('Error getting JSON data type: ', $err:code, ": ", $err:description, ' (', $err:module, ' ', $err:line-number, ':', $err:column-number, ')') }
    let $serialized := try { ju:serialize-json($json) } catch * { concat('Error serializing JSON: ', $err:code, ": ", $err:description, ' (', $err:module, ' ', $err:line-number, ':', $err:column-number, ')') }
    return
        <result>
            <type>{$type}</type>
            {
                if ($type = 'array') then
                    (
                        <array-size>{array:size($json)}</array-size>,
                        <suggestions>
                            <suggestion>$json?*</suggestion>
                            <suggestion>array:size($json)</suggestion>
                            <suggestion>array:get($json, 1)</suggestion>
                        </suggestions>
                    )
                else if ($type = 'map') then
                    (
(:                        <map-size>{map:size($json)}</map-size>,:)
                        <map-size>{count(map:keys($json))}</map-size>,
                        <map-keys>{map:keys($json) ! <key>{.}</key>}</map-keys>,
                        <suggestions>
                            <suggestion>map:keys($json)</suggestion>
                            <suggestion>$json?key</suggestion>
                        </suggestions>
                    )
                else
                    ()
            }
            <serialization>{$serialized}</serialization>
        </result>
};