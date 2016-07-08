# Cucumber Salad
### A (naive) way to parallelize Cucumber runs

#### Process
This script attempts to parallelize Cucumber runs by taking each grouping of
tags, splitting them into nearly equal lists, then merging each list for the
individual tags to produce a given number of equally long lists of tags with
a similar mix of tag types in each list.

These lists are then run in Cucumber as separate processes that produce JSON
output. When each of these processes finish, an additional run for all Scenarios
tagged with @nightly-jobs are run in series. This additional run produces an
additional JSON file.

Finally, all the JSON files are merged into a single result file.

#### Requirements
| Req | Description |
| --- | ----------- |
| known_tags.csv | A file listing all grouping tags. If your Scenarios are stratified by speed somehow, use those tags. |
| 'headless' profile | A Cucumber profile named 'headless'. You can certainly edit this in code. |

#### Caveats
* You'll need enough memory to run this stuff in parallel, of course.
* Currently, this must be run from the root directory of your Cucumber project
 so that the Cucumber processes can find the cucumber.yml file.