xquery version "3.0";

module namespace config = "http://history.state.gov/ns/xquery/twitter/config";

import module namespace secrets = "http://history.state.gov/ns/xquery/twitter/secrets" at 'twitter-secrets.xqm';

declare function config:consumer-key() {secrets:read-secret('consumer-key')};
declare function config:consumer-secret() {secrets:read-secret('consumer-secret')};
declare function config:access-token() {secrets:read-secret('access-token')};
declare function config:access-token-secret() {secrets:read-secret('access-token-secret')};

declare variable $config:download-chunk-size := 10;
