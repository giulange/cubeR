# cubeR

A package automating Landsupport data processing:

* S2 images download (from the s2.boku.eodc.eu) (`vignettes/dwnld.R`)
* reprojecting and retiling (`vignettes/tile.R` / `prepareTiles()`)
* cloud mask generation (`vignettes/mask.R` / `prepareMasks()`)
* NDVI computation (`vignettes/ndvi.R` / `prepareNdvi()`)
* computing composites (`vignettes/which.R` & `vignettes/composite.R` / `prepareWhich()` & `prepareComposites()`)

## Installation

Clone this repo.

## Usage

* Prepare you own config files based on `vignettes/configEodc.R`.
* Use scripts from command line, e.g. `Rscript vignettes/tile.R myConfig.R zozlak myPswd myRegionOfInterest 2018-05-01 2018-05-31` 
  or use package functions interactively - see `vignettes/scratchpad.R`.
