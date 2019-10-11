# cubeR

A package automating Landsupport data processing:

* S2 images download (from the s2.boku.eodc.eu) (`vignettes/dwnld.R`)
* cloud mask generation (`vignettes/mask.R` / `prepareMasks()`)
* NDVI computation (`vignettes/indicator.R` / `prepareIndicators()`)
* computing composites (`vignettes/which.R` & `vignettes/composite.R` / `prepareWhich()` & `prepareComposites()`)
* reprojecting and retiling (`vignettes/tile.R` / `prepareTiles()`)

## Installation

* Clone this repo.
* Assure you have proper runtime environment - see below.

### Windows

* Install Python 2 or 3 (installers are available at https://www.python.org/downloads/windows/)
* Install Numpy - run `python -m pip install numpy` or `python3 -m pip install numpy` in the console (depending on your Python version)
* Install gdal (version 2.4 or newer) including Python gdal bindings.
  Binary installers are available trough [eo4w](https://trac.osgeo.org/osgeo4w/wiki/WikiStart) and [gisinternals](http://www.gisinternals.com/release.php).
  If you want, you can also compile from source (https://github.com/OSGeo/gdal)
* Install R packages. In R run:
    ```r
    install.packages('devtools')
    devtools::install_github('IVFL-BOKU/sentinel2')
    devtools::install_github('IVFL-BOKU/landsupport')
    ```
### Linux

* Make sure you have Python with numpy and gdal bindings installed.
    * In Ubuntu/Debian run `sudo apt install -y python3 python3-numpy python3-gdal`
    * In Fedora/Centos/RHEL run `sudo yum install -y python3 numpy`
* Install gdal
    * In Ubuntu/Debian run `sudo apt install -y python-gdal gdal-bin`
    * In Fedora/Centos/RHEL run `sudo yum install -y gdal`
* Install R and libraries required to compile R packages
    * In Ubuntu/Debian run `sudo apt install -y r-base libxml2-dev libssl-dev libcurl4-openssl-dev libgdal-dev libudunits2-dev`
    * In Fedora/Centos/RHEL run `sudo yum install -y R-core libxml2-devel libcurl-devel openssl-devel gdal-devel udunits2-devel`
* Install R packages. In R run:
    ```r
    install.packages('devtools')
    devtools::install_github('IVFL-BOKU/sentinel2')
    devtools::install_github('IVFL-BOKU/landsupport')
    ```

### Docker

* Build a Docker image with `cd {thisRepositoryDirectory} && docker build -t cubeR docker`
* Run the a Docker container `docker run -ti cubeR`.
  The package code is in `/root/landsupport` directory.
  (please consult the [Docker run documentation](https://docs.docker.com/engine/reference/run/) for more advanced settings, e.g. mapping host directories into the container, etc.)

## Usage

(all paths are relative to the repository location)

* Prepare you own config files based on `scripts/config/configEodc.R`.
* Create source data index for a given config, region of interest and time period by running the `scripts/init.R` from a command line, e.g. 
  `Rscript scripts/init.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31 apiLogin apiPassword`
* Use scripts from command line, e.g. `Rscript scripts/tile.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31`
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

