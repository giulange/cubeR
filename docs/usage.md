## Usage

(all paths are relative to the repository location)

* Prepare you own config files based on `scripts/config/configEodc.R`.
* Create source data index for a given config, region of interest and time period by running the `scripts/init.R` from a command line, e.g. 
    ```
    Rscript scripts/init.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31 apiLogin apiPassword
    ```
* Use scripts from command line, e.g. `Rscript scripts/tile.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31`
  or use package functions interactively - see `vignettes/scratchpad.R`.

