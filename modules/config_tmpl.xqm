xquery version "3.0";

module namespace config = "http://history.state.gov/ns/xquery/twitter/config";

(:~ A library module for your application's Twitter credentials. You can get your credentials from 
    https://dev.twitter.com/apps/.
 :)

declare variable $config:consumer-key := '';
declare variable $config:consumer-secret := '';
declare variable $config:access-token := '';
declare variable $config:access-token-secret := '';