# cubeR

A package automating Landsupport data processing:

* S2 images download (from the s2.boku.eodc.eu) (`vignettes/dwnld.R`)
* cloud mask generation (`vignettes/mask.R` / `prepareMasks()`)
* NDVI computation (`vignettes/indicator.R` / `prepareIndicators()`)
* computing composites (`vignettes/which.R` & `vignettes/composite.R` / `prepareWhich()` & `prepareComposites()`)
* reprojecting and retiling (`vignettes/tile.R` / `prepareTiles()`)

## Installation

* Install Python
    * If you are using Linux almost for sure it is already installed. If not, simply install from your distribution package.
    * If you are using Windows installer is available at https://www.python.org/downloads/windows/
* Install gdal
    * If you are using Linux install from a package (e.g. `gdal-bin` and `python-gdal` on Ubuntu and Debian or `gdal` on Fedora).
    * If you are using Windows either use precompiled binaries available trough [eo4w](https://trac.osgeo.org/osgeo4w/wiki/WikiStart) or [gisinternals](http://www.gisinternals.com/release.php) (easy option) or build from source (advanced option).
* Install the package itself
  ```r
  install.packages('devtools')
  devtools::install_github('IVFL-BOKU/landsupport')
  ```

## Usage

* Prepare you own config files based on `scripts/config/configEodc.R`.
* Create source data index for a given config, region of interest and time period by running the ` from scripts/init.R` from a command line, e.g. 
  `Rscript scripts/init.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31 apiLogin apiPassword`
* Use scripts from command line, e.g. `Rscript scripts/tile.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31`.
  or use package functions interactively - see `vignettes/scratchpad.R`.

### Directory structure

TODO

### Paralelization

TODO

### Tracking progress

TODO

### Scripts (modules)

TODO

### init.R

TODO

#### download.R

TODO

#### mask.R

TODO

#### indicator.R

TODO

#### which.R

TODO

#### composite.R

TODO

#### aggregate.R

TODO

#### cropmask.R

TODO

#### tile.R

TODO
