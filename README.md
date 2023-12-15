# @HistoryAtState Twitter Archive

[![exist-db CI](https://github.com/HistoryAtState/twitter/actions/workflows/build.yml/badge.svg)](https://github.com/HistoryAtState/twitter/actions/workflows/build.yml)

Archive of tweets by the Office of the Historian's official Twitter account, [@HistoryAtState](https://twitter.com/HistoryAtState)

## Build

1. Single `xar` file: The `collection.xconf` will only contain the index, not any triggers!

    ```shell
    ant
    ```

    1. Since Releases have been automated when building locally you might want to supply your own version number (e.g. `X.X.X`) like this:

    ```shell
    ant -Dapp.version=X.X.X
    ```

## Release

Releases for this data package are automated. Any commit to the `master`` branch will trigger the release automation.

All commit message must conform to [Angular Commit Message Conventions](https://github.com/angular/angular.js/blob/master/DEVELOPERS.md#-git-commit-guidelines) to determine semantic versioning of releases, please adhere to these conventions, like so:

| Commit message  | Release type |
|-----------------|--------------|
| `fix(pencil): stop graphite breaking when too much pressure applied` | Patch Release |
| `feat(pencil): add 'graphiteWidth' option` | ~~Minor~~ Feature Release |
| `perf(pencil): remove graphiteWidth option`<br/><br/>`BREAKING CHANGE: The graphiteWidth option has been removed.`<br/>`The default graphite width of 10mm is always used for performance reasons.` | ~~Major~~ Breaking Release |

When opening PRs commit messages are checked using commitlint.