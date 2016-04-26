xquery version "3.0";

module namespace config = "http://history.state.gov/ns/xquery/twitter/config";

(:~ A library module for your application's Twitter credentials. You can get your credentials from 
    https://dev.twitter.com/apps/.
 :)

declare function config:consumer-key() {''};
declare function config:consumer-secret() {''};
declare function config:access-token() {''};
declare function config:access-token-secret() {''};
