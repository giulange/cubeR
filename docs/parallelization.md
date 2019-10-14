### Parallelization

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

