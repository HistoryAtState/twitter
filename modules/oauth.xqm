xquery version "3.0";

module namespace oauth="http://history.state.gov/ns/xquery/oauth";

(:~ A library module for signing and submitting OAuth requests such as the kind needed for the Twitter v1.1 API.

    The EXPath Crypto library supplies the HMAC-SHA1 algorithm. The EXPath HTTP Client library makes the HTTP requests.
    The OAuth standard requires a "nonce" parameter - a random string.  Since there is no implementation-independent
    nonce function in XQuery, we must rely on implementation-specific functions.  For eXist-db we use util:uuid().

    @see http://oauth.net/core/1.0/
    @see http://tools.ietf.org/html/rfc5849
    @see http://marktrapp.com/blog/2009/09/17/oauth-dummies
    @see http://expath.org/spec/http-client
    @see http://expath.org/spec/crypto 
    @see http://exist-db.org/exist/apps/fundocs/view.html?uri=http://exist-db.org/xquery/util
 :)

import module namespace crypto="http://expath.org/ns/crypto";
import module namespace http="http://expath.org/ns/http-client";
import module namespace util="http://exist-db.org/xquery/util";

declare function oauth:send-request(
    $consumer-key, 
    $consumer-secret,
    $access-token,
    $access-token-secret,
    $method,
    $url,
    $nonce,
    $signature-method, 
    $timestamp, 
    $version
    ) {
        let $base-url := if (contains($url, '?')) then substring-before($url, '?') else $url
        let $query-string := if (contains($url, '?')) then substring-after($url, '?') else ()
        let $query-string-params :=
            for $param in tokenize($query-string, '&amp;')
            let $name := substring-before($param, '=')
            let $value := substring-after($param, '=')
            return
                <param name="{$name}" value="{$value}"/>
        let $params := 
            (
            $query-string-params,
            <param name="oauth_consumer_key" value="{$consumer-key}"/>,
            <param name="oauth_nonce" value="{$nonce}"/>,
            <param name="oauth_signature_method" value="{$signature-method}"/>,
            <param name="oauth_timestamp" value="{$timestamp}"/>,
            <param name="oauth_token" value="{$access-token}"/>,
            <param name="oauth_version" value="{$version}"/>
            )
        let $parameter-string := oauth:params-to-oauth-string($params, '&amp;')
        let $signature-base-string := 
            string-join(
                (
                upper-case($method),
                encode-for-uri($base-url),
                encode-for-uri($parameter-string)
                )
                ,
                '&amp;'
            )
        let $signing-key := concat(encode-for-uri($consumer-secret), '&amp;', encode-for-uri($access-token-secret))
        let $oauth-signature := crypto:hmac($signature-base-string, $signing-key, 'HmacSha1', 'base64')
        let $final-params := 
            (
            $params, 
            <param name="oauth_signature" value="{$oauth-signature}"/>
            )
        let $final-parameter-string := oauth:params-to-oauth-string($final-params, ', ')
        let $authorization-header-value := concat('OAuth ', $final-parameter-string)
        let $request := 
            <http:request href="{$url}" method="{$method}">
                <http:header name="Authorization" value="{$authorization-header-value}"/>
            </http:request>
        let $response := http:send-request($request)
        return 
            (
            $request
            ,
            $response
            )
};

declare function oauth:nonce() { util:uuid() };

declare variable $oauth:signature-method := 'HMAC-SHA1';

declare variable $oauth:oauth-version := '1.0';

(: Generates an OAuth timestamp, which takes the form of the number of seconds since the Unix Epoch.
   You can test these values against http://www.epochconverter.com/.
   @see http://en.wikipedia.org/wiki/Unix_time
 :)
declare function oauth:timestamp() as xs:unsignedLong {
    let $unix-epoch := xs:dateTime('1970-01-01T00:00:00Z')
    let $now := current-dateTime()
    let $duration-since-epoch := $now - $unix-epoch
    let $seconds-since-epoch :=
        days-from-duration($duration-since-epoch) * 86400 (: 60 * 60 * 24 :)
        +
        hours-from-duration($duration-since-epoch) * 3600 (: 60 * 60 :)
        +
        minutes-from-duration($duration-since-epoch) * 60
        +
        seconds-from-duration($duration-since-epoch)
    return
        xs:unsignedLong($seconds-since-epoch)
};

(: prepares OAuth authentication parameters :)
declare function oauth:params-to-oauth-string($params as element(param)+, $separator as xs:string) {
    string-join(
        for $param in $params
        let $name := encode-for-uri($param/@name)
        let $value := encode-for-uri($param/@value)
        order by $name, $value
        return
            concat($name, '=', $value)
        ,
        $separator
    )
};