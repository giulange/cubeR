# directory where the package was cloned
cubeRpath = 'ADJUST'
# file containing the target grid (every feature must provide the TILE property)
gridFile = 'ADJUST'
# directory for storing temporary files
tmpDir = 'ADJUST'
# directory storing rasters before retiling
rawDir = 'ADJUST'
# directory storing rasters aggregated to periods
periodsDir = 'ADJUST'
# directory storing rasters after retiling to the target grid (see the gridFile parameter)
tilesDir = 'ADJUST'
# directory storing overviews
overviewsDir = '/eodc/private/boku/ACube2/overviews'
# raw images cache file path template (see `?getCachePath`)
cacheTmpl = 'ADJUST/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

# list of bands to be downloaded and tiled
bands = c('B04', 'B08', 'SCL')
# maximal accepted granules' cloud coverage
cloudCov = 0.4
# number of workers (cores)
nCores = ADJUST
# each worker (core) is assigned chunksPerCore data chunks (generally you shouldn't need to tune this property)
chunksPerCore = 10

# download method "download", "copy" or "symlink"
# (two latter ones work only on machines with a direct access to the BOKU's EODC storage)
dwnldMethod = 'download'
# maximum accepted local files to be deleted during the download (to avoid hitting own foot)
dwnldMaxRemovals = 100
# s2.boku.eodc.eu database connection paramerters required for the "symlink" download method
dwnldDbParam = list()
## parameters required for the "download" download method
# number of parallel downloads
dwnldNCores = 4
# see `?sentinel2::S2_download`
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 3

# description of cloud masks - parameters passed to prepareMasks() - see `?prepareMasks` (remember minArea and bufferSize unit is a 20m pixel)
maskParam = list(
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
# should already existing masks be skipped (TRUE) or reprocessed anyway (FALSE)
maskSkipExisting = TRUE

# indicators definitions
indicatorIndicators = list(
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
# should already existing indicator images be skipped (TRUE) or reprocessed anyway (FALSE)
indicatorSkipExisting = TRUE

# band names of bands used to compute within-a-period maxima (can be more than one band)
whichBands = c('NDVI2')
# prefix preppended to the orignal band name to get the target "which band name"
whichPrefix = 'NMAX'
# prefix preppended to the orignal band name to get the "day of year with a within-a-period maximum value band name" (if empty string this indicator is not computed)
whichDoyPrefix = 'DOYMAX'
# processing block size (affects memory usage)
whichBlockSize = 1024
# should already existing "which" images be skipped (TRUE) or reprocessed anyway (FALSE)
whichSkipExisting = TRUE

# band names of bands for which composites should be computed
compositeBands = list(
  band      = c('NDVI2'),
  whichBand = c('NMAXNDVI2'),
  outBand   = c('NDVI2')
)
# processing block size (affects memory usage)
compositeBlockSize = 2048
# should already existing composite images be skipped (TRUE) or reprocessed anyway (FALSE)
compositeSkipExisting = TRUE

# bands to be aggregated into quantiles
aggregateBands = c('NDVI2')
# processing block size (affects memory usage)
aggregateBlockSize = 512
# quantiles to be computed
aggregateQuantiles = c(0.05, 0.5, 0.98)
# should rasters with valid acquisition counts be computed?
aggregateCounts = FALSE
# band which should be used to compute counts
aggregateCountsBand = 'NDVI2'
# counts output band name
aggregateCountsOutBand = 'N2'
# should already computed quantile images be skipped (TRUE) or reprocessed anyway (FALSE)
aggregateSkipExisting = TRUE

tileRawBands = character()
tilePeriodBands = list(
  '1 month' = c('DOYMAXNDVI2', 'NMAXNDVI2', 'NDVI2'),
  '1 year' = c('NDVI2q05',  'NDVI2q50',  'NDVI2q98')
)
# should already existing tiles be skipped (TRUE) or reprocessed anyway (FALSE)
tileSkipExisting = TRUE
# reprojection resampling algorithm - see `man gdalwap``
tileResamplingMethod = 'near'
# additional gdalwarp parameters used while reprojection & retiling - see `man gdalwap``
tileGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'

