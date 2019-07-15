# directory where the package was cloned
cubeRpath = '/eodc/private/boku/software/cubeR'
# file containing the grid (every feture must provide the TILE property)
gridFile = '/eodc/private/boku/ACube/shapefiles/Grid_LAEA5210_100K_polygons.shp'
# directory for storing temporary files
tmpDir = '/eodc/private/boku/ACube2/tmp'
# directory storing rasters before retiling
rawDir = '/eodc/private/boku/ACube2/raw'
# directory storing rasters aggregated to periods
periodsDir = '/eodc/private/boku/ACube2/periods'
# directory storing rasters after retiling to the target grid (see the gridFile parameter)
tilesDir = '/eodc/private/boku/ACube2/tiles'
# directory storing overviews
overviewsDir = '/eodc/private/boku/ACube2/overviews'
# raw images cache file path template (see `?getCachePath`)
cacheTmpl = '/eodc/private/boku/ACube2/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

# list of bands to be downloaded and tiled
bands = c('B02', 'B03', 'B04', 'B08', 'B8A', 'B11', 'B12', 'SCL', 'LAI', 'TCI')
# maximal accepted granules' cloud coverage
cloudCov = 0.4
# number of workers (cores)
nCores = 40
# each worker (core) is assigned chunksPerCore data chunks (generally you shouldn't need to tune this property)
chunksPerCore = 10

# download method "download", "copy" or "symlink"
# (two latter ones work only on machines with a direct access to the BOKU's EODC storage)
dwnldMethod = 'symlink'
# maximum accepted local files to be deleted during the download (to avoid hitting own foot)
dwnldMaxRemovals = 100
# s2.boku.eodc.eu database connection paramerters required for the "symlink" download method
dwnldDbParam = list(host = '10.250.16.131', port = 5432, user = 'eodc', dbname = 'bokudata')
## parameters required for the "download" download method
# number of parallel downloads
dwnldNCores = 4
# see `?sentinel2::S2_download`
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

# description of cloud masks - parameters passed to prepareMasks() - see `?prepareMasks` (remember minArea and bufferSize unit is a 20m pixel)
maskParam = list(
  list(bandName = 'CLOUDMASK1', minArea = 9L, bufferSize = 5L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
# should already existing masks be skipped (TRUE) or reprocessed anyway (FALSE)
maskSkipExisting = TRUE

# indicators definitions
indicatorIndicators = list(
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'NDTI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B12'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'MNDWI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B11'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'NDBI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B8A'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  list(bandName = 'BSI2',   resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B12', 'B' = 'B04', 'C' = 'B8A', 'D' = 'B02'), equation = '((A.astype(float) + B) - (C + D) ) / (0.0000001 + A + B + C + D)'),
  list(bandName = 'BLFEI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B04', 'C' = 'B12', 'D' = 'B11'), equation = '((A.astype(float) + B + C) / 3 - D) / (0.0000001 + (A + B + C) / 3 + D)')
)
# should already existing indicator images be skipped (TRUE) or reprocessed anyway (FALSE)
indicatorSkipExisting = TRUE

# band names of bands used to compute within-a-period maxima (can be more than one band)
whichBands = c('NDVI1', 'NDVI2')
# prefix preppended to the orignal band name to get the target "which band name"
whichPrefix = 'NMAX'
# processing block size (affects memory usage)
whichBlockSize = 2048
# should already existing "which" images be skipped (TRUE) or reprocessed anyway (FALSE)
whichSkipExisting = TRUE

# band names of bands for which composites should be computed
compositeBands = list(
  band      = c('NDVI1',     'LAI',       'TCI',       'NDVI2',     'LAI',       'TCI'),
  whichBand = c('NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  outBand   = c('NDVI1',     'LAI1',      'TCI1',      'NDVI2',     'LAI2',      'TCI2')
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
aggregateQuantiles = c(0.05, 0.5, 0.95)
# should already computed quantile images be skipped (TRUE) or reprocessed anyway (FALSE)
aggregateSkipExisting = TRUE

tileRawBands = character()
tilePeriodBands = list(
  '1 month' = c('LAI1', 'NDVI1', 'TCI1', 'LAI2', 'NDVI2', 'TCI2'),
  '1 year' = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
# should already existing tiles be skipped (TRUE) or reprocessed anyway (FALSE)
tileSkipExisting = TRUE
# reprojection resampling algorithm - see `man gdalwap``
tileResamplingMethod = 'near'
# additional gdalwarp parameters used while reprojection & retiling - see `man gdalwap``
tileGdalOpts = '-multi -wo NUM_THREADS=2 -wo "COMPRESS=DEFLATE" -wo "TILED=YES" -wo "BLOCKXSIZE=512" -wo "BLOCKYSIZE=512"'

# tiles to be merged into overviews
overviewPeriodBands = list(
  '1 month' = c('LAI1',    'LAI2', 'NDVI1', 'NDVI2', 'TCI1', 'TCI2'),
  '1 year'  = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
overviewResolution = 100
overviewResamplingMethod = 'bilinear'
overviewGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -wo "COMPRESS=DEFLATE" -wo "TILED=YES" -wo "BLOCKXSIZE=512" -wo "BLOCKYSIZE=512"'
overviewNCores = 16
overviewSkipExisting = TRUE

