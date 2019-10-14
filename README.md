# cubeR

A package automating Landsupport data processing.



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
* Install gdal (version 2.4 or newer is required)
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
    ```
    Rscript scripts/init.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31 apiLogin apiPassword
    ```
* Use scripts from command line, e.g. `Rscript scripts/tile.R myConfig.R myRegionOfInterest 2018-05-01 2018-05-31`
  or use package functions interactively - see `vignettes/scratchpad.R`.

### Configuration files

### Scripts (modules)

TODO

### init.R

TODO

#### download.R

TODO

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

Stores downloaded data in the `rawDir`.

##### Performance

TODO

##### Configuration

TODO

#### mask.R

Computes valid pixels mask based on the Sentinel 2 L2A SCL band.

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

Reads data from the `rawDir` and stores results into the `rawDir`.

##### Performance

TODO

##### Configuration

TODO

#### indicator.R

Technically it is a wrapper for the [gdal_calc](https://gdal.org/programs/gdal_calc.html) taking care of running it in parallel and some data preparation steps.

Used to compute indicators which can be expressed (and effectively computed) using a single numpy expression.

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

Reads data from the `rawDir` and stores results into the `rawDir`.

##### Performance

Depending on the `equation` complexity (see the configuration section below) the performance bottleneck may be either storage speed (simple equations) or CPU (complex ones).

##### Configuration

* `indicatorSkipExisting` allowing to skip computations of already existing output images.
* `indicatorIndicators` configuration property being a list of indicators to be computed. Each indicator is described by:
    * `bandName` output band/indicator name, e.g. `NDVI`.
    * `resolution` output data resolution. If some input rasters are in a different resolution, they will be automatically resampled.
    * `mask` name of a band to be used as a valid pixels mask.
    * `factor` output data scalling factor. Output data are saved using the 2B integer type (values ranging from -32768 to 32767). The `factor` parameter allows to rescale values coming from the `equation` computations into this range, e.g. for NDVI `10000` is a good `factor`.
    * `bands` list of input bands/indicators. Should be a named vector with every band/indicator denoted by a single capital letter, e.g. `c('A' = 'B04', 'B' = 'B08')`.
    * `equation` a numpy equation computing the indicator. Remember that:
        * If input data are integers you may need to cast the to floats to avoid strange results (e.g. getting only value of 0 while computing an NDVI), e.g. `(A.astype(float) - B) / (+ A + B)`.
        * Make sure you will never divide by zero. Add a neglectably small constant when needed, e.g. `'(A.astype(float) - B) / (0.0000001 + A + B)`.

A complete configuration for computing an NDVI (at a 10 m resolution and using a mask named `CLOUDMASK`) looks as follows:
```r
indicatorSkipExisting = TRUE
indicatorIndicators = list(
  list(bandName = 'NDVI',  resolution = 10, mask = 'CLOUDMASK', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
```

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

#### composite.R

TODO

##### Command line arguments

* A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.
* A `period` argument specifying the aggregation period. Period description consists of a number and a period type name (`day`, `month` or `year`), e.g. `1 year` or `10 days`. Period type name can be also provided in plural, e.g. `2 months`.

##### Data input/output

Reads data from both `rawDir` and `periodsDir` (*which* files) and stores results into the `periodsDir`.

##### Performance

TODO

##### Configuration

TODO

#### aggregate.R

TODO

##### Command line arguments

* A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.
* A `period` argument specifying the aggregation period. Period description consists of a number and a period type name (`day`, `month` or `year`), e.g. `1 year` or `10 days`. Period type name can be also provided in plural, e.g. `2 months`.

##### Data input/output

Reads data from both `rawDir` and stores results into the `periodsDir`.

##### Performance

TODO

##### Configuration

TODO

#### cropmask.R

TODO

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

TODO

##### Performance

TODO

##### Configuration

TODO

#### tile.R

TODO

##### Command line arguments

A standard set of `configFilePath`, `regionName`, `startDate` and `endDate`.

##### Data input/output

Reads data from both `rawDir` and `periodsDir` and stores results into the `tilesDir`.

##### Performance

TODO

##### Configuration

TODO

### Directory structure

#### Main directories

* *RawDir* stores data following Sentinel 2 grid and acquisition dates. It includes Sentinel 2 L2A data (acquired during the *download* step) as well as masks and indicators computed during *mask* and *indicator* steps.
* *PeriodsDir* stores data on the Sentinel 2 grid aggregated to broader time periods (e.g. monthly and yearly aggregates). These data come from *aggregate*, *which*, *composite* and *cropmask* steps.
* *TilesDir* stores data reprojected and retiled to the target grid - results of the *tile* step.

Within each directory data are organized according to the tiling grid with every tile having corresponding cubdirectory.

#### File names

Data are stored as raster files (JPEG2000 for Sentinel L2A data, TIFF for data computed by the package) using a `{date/period}_{tile}.tif` naming scheme. The `{date/period}` is:

* either an acquisition date in the `YYYY-MM-DD` format 
* or a period in the `{date}{length}` format, e.g.
  `2018y1` - 1 year period for year 2018
  `2017-04m1` - monthly period for April 2017

#### Suplementary directories

* *TmpDir* stores temporary data. For performance reasons (all the output data firstly computed in it and then moved to a target location) it is good to keep it on the same drive/partition than the main data storage directories.
* *CacheDir* stores data available for a given processing chain (see the *init* step description).

### Paralelization

All processing steps can be run in parallel. The number of parallel tasks is controlled by the `nCores` configuration parameter.

While processing in parallel you must assure **enough memory is available.**
Memory consumption rises lineary with the number of parallel tasks.
Different processing steps may have diffent memory requirements but they can always be tuned using configuration settings:

* `{step}BlockSize` Memory consumption is proportional to the square of the block size. Large blocks speed up computations but if rasters are saved using `-co "TILED=YES" -co "BLOCKXSIZE={N}" -co "BLOCKYSIZE={N}"` gdal creation options (see `{step}gdalOpts` configuration parameter) rising it above `{N}` will give neglectable gains (also in such a case the block size should be a multiple of `{N}`).
  In most cases value of 512 should do the job. 
  See also the remark below.
* `{step}GdalOpts` The `--config  GDAL_CACHEMAX {cacheSize}` gdal option (see discussion of the `GDAL_CACHEMAX` on the [gdal wiki](https://trac.osgeo.org/gdal/wiki/ConfigOptions)) should not exceed amount of available memory divided by the number of parallel tasks.

Remarks:

* **Leave some memory for the operating system I/O cache.** Computations performed by this package are very I/O intensive and for an effective I/O the operating system must be able to allocate an I/O cache in the memory. While choosing the right `{step}BlockSize` and `GDAL_CACHEMAX` values please make sure there will be a gigabyte or two of memory left per parallel process which the operating system can use for the I/O cache.
* Only actual computations are parallelized. Every processing step includes also an initialization phase where a set of required input and output data is computed and it is checked if all input data are available. This phase in run as a single process. While compering to the actual computations it takes neglectable amounts of time it can be still up to dozen of minutes for huge processing tasks (it depends mostly on the storage performance).

### Logging and progress tracking

Every processing step emits logs on the standard output and standard error. The log structure is as follows:

* The first line contains sums up the processing task - the script being run, parameters passed to it and a timestamp.
* The second line contains the total number of output products to be produced.
* Following lines report processing progress.
  The number of lines depends on `nCores` and `chunksPerCore` configuration properties.
  Basically output products list is divided into `nCores * chunksPerCore` chunks which are then assigned to `nCores` parallel jobs.
  Every time a job picks up a next chunk it prints a log line describing which output products are contained in the chunk.
* The last line contains a processing summary:
    * number of output products, 
    * number of valid ones,
    * number of actually processed output products (some could be ready before processing was started),
    * a timestamp
    * an average time spend per single output product.

The processing progress can be estimated as `({numberOfEmmitedLogLine} - 2) / (nCores * chunksPerCore)`.
If you want a more detailed progress tracking (e.g. for large processing tasks), increase the `chunksPerCore` configuration setting.
There is no noticable performance gain from splitting the processing in the lower number of chunks.
