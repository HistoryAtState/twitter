# @HistoryAtState Twitter Archive

Archive of tweets by the Office of the Historian's official Twitter account, [@HistoryAtState](https://twitter.com/HistoryAtState)

## Build

1. Single `xar` file: The `collection.xconf` will only contain the index, not any triggers!
    ```shell
    ant
    ```

2. DEV environment: The replication triggers for the producer server are enabled in  `collection.xconf` and point to the dev server's replication service IP.
    ```shell
    ant xar-dev
    ```

3. PROD environment: Same as in 2. but for PROD destination
    ```shell
    ant xar-prod
    ```
