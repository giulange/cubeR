#### which.R

TODO

##### Command line arguments

* A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.
* A `period` argument specifying the aggregation period. Period description consists of a number and a period type name (`day`, `month` or `year`), e.g. `1 year` or `10 days`. Period type name can be also provided in plural, e.g. `2 months`.

##### Data input/output

Reads data from the `rawDir` and stores results into the `periodsDir`.

##### Performance

This processing step consists of very simple computations and depends mostly on the storage performance.

##### Configuration

TODO

