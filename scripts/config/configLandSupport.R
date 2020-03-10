# ~~~~~~~~~~~~~~~~~ PATH
# directory where the package was cloned
cubeRpath = '/home/giuliano/git/cubeR'
# # dir where all Project stuff is stored:
# wdir = '/media/GFTP/landsupport/cubeR'

# file containing the grid (every feture must provide the TILE property)
gridFile = '/media/GFTP/landsupport/cubeR/tile_prop/Grid_LAEA5210_100K_polygons.geojson'

# directory for storing temporary files
tmpDir = '/media/GFTP/landsupport/cubeR/tmp'

# directory storing rasters before retiling
# - It stores all files being on the same aggregation level as original Sentinel 2 
#   images (acquisition of a given UTM tile at a given date).
#   This directory is an output of the "download" step, both input and output for "mask", 
#   "indicator" & "which" step and an input for "composite" and "aggregate" steps.
rawDir = '/media/GFTP/landsupport/cubeR/raw'

# directory storing rasters aggregated to periods
# - It stores all time aggregates (monthly, yearly, etc.) on the Sentinel 2 UTM grid.
#   This directory is an output for "aggregate" and "composite" steps and an input
#   for the "tile" step.
periodsDir = '/media/GFTP/landsupport/cubeR/periods'

# directory storing rasters after retiling to the target grid (see the gridFile parameter)
# - It stores final data (no matter of their time aggregation level) retiled and reprojected 
#   to the target grid. It is an output of the "tile" step.
tilesDir = '/media/GFTP/landsupport/cubeR/re-tiled'

# directory storing overviews
# - It is not interesting for us in a normal processing pipeline and we may skip it.
overviewsDir = '/media/GFTP/landsupport/cubeR/overviews'

# raw images cache file path template (see `?getCachePath`)
# - It is a template for a file caching a list of source Sentinel 2 files 
#   for a given processing. We need it to distinguish lacks of input data 
#   coming from processing errors from lacks of input data caused by changes 
#   in raw Sentinel 2 data availbility. E.g. the "composite" step (see the 
#   presentation in attachment) needs to know if images coming from the 
#   "download" step which lack corresponding images being a result of the 
#   "which" step are errors in the workflow or maybe they are results of a 
#   more recent "download" step runs. In regard to this config option feel 
#   free to adjust the directory and leave the file name part as it is.
cacheTmpl = '/media/GFTP/landsupport/cubeR/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'

# ~~~~~~~~~~~~~~~~~ DOWNLOAD

# list of bands to be downloaded and tiled
# bands = c('B02', 'B03', 'B04', 'B08', 'B8A', 'B11', 'B12', 'SCL', 'LAI', 'TCI') # LS
bands = c('B04', 'B08', 'SCL') # test

# maximal accepted granules' cloud coverage
cloudCov = 0.4
# number of workers (cores)
nCores = 4
# each worker (core) is assigned chunksPerCore data chunks
# (generally you shouldn't need to tune this property)
chunksPerCore = 10

# download method "download", "copy" or "symlink"
# (two latter ones work only on machines with a direct access to the BOKU's EODC storage)
dwnldMethod = 'download'
# maximum accepted local files to be deleted during the download (to avoid hitting own foot)
dwnldMaxRemovals = 100
# <<symlink>>
# s2.boku.eodc.eu database connection parameters required for the "symlink" download method
# dwnldDbParam = list(host = '10.250.16.131', port = 5432, user = 'eodc', dbname = 'bokudata')
# <<download>>
# parameters required for the "download" download method
# number of parallel downloads
dwnldNCores = 4
# see `?sentinel2::S2_download`
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 3

# ~~~~~~~~~~~~~~~~~ MASK

# description of cloud masks - parameters passed to prepareMasks() - see `?prepareMasks` (remember minArea and bufferSize unit is a 20m pixel)
maskParam = list(
  # list(bandName = 'CLOUDMASK1', minArea = 9L, bufferSize = 5L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = c(3L, 8L:10L)),
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
# should already existing masks be skipped (TRUE) or reprocessed anyway (FALSE)
maskSkipExisting = TRUE

# ~~~~~~~~~~~~~~~~~ INDICATORS

# indicators definitions
indicatorIndicators = list(
  # list(bandName = 'NDVI1',  resolution = 10, mask = 'CLOUDMASK1', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  # list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  # list(bandName = 'NDTI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B12'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  # list(bandName = 'MNDWI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B11'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  # list(bandName = 'NDBI2',  resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B11', 'B' = 'B8A'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)'),
  # list(bandName = 'BSI2',   resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B12', 'B' = 'B04', 'C' = 'B8A', 'D' = 'B02'), equation = '((A.astype(float) + B) - (C + D) ) / (0.0000001 + A + B + C + D)'),
  # list(bandName = 'BLFEI2', resolution = 20, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B03', 'B' = 'B04', 'C' = 'B12', 'D' = 'B11'), equation = '((A.astype(float) + B + C) / 3 - D) / (0.0000001 + (A + B + C) / 3 + D)')
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B04', 'B' = 'B08'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
# should already existing indicator images be skipped (TRUE) or reprocessed anyway (FALSE)
indicatorSkipExisting = TRUE

# ~~~~~~~~~~~~~~~~~ WHICH

# band names of bands used to compute within-a-period maxima (can be more than one band)
# whichBands = c('NDVI1', 'NDVI2')
whichBands = c('NDVI2')
# prefix preppended to the orignal band name to get the target "which band name"
whichPrefix = 'NMAX'
# prefix preppended to the orignal band name to get the "day of year with a within-a-period maximum value band name" (if empty string this indicator is not computed)
whichDoyPrefix = 'DOYMAX'
# processing block size (affects memory usage)
whichBlockSize = 1024
# should already existing "which" images be skipped (TRUE) or reprocessed anyway (FALSE)
whichSkipExisting = TRUE

# ~~~~~~~~~~~~~~~~~ COMPOSITE

# band names of bands for which composites should be computed
compositeBands = list(
  # band      = c('NDVI1',     'LAI',       'TCI',       'NDVI2',     'LAI',       'TCI'),
  # whichBand = c('NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI1', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  # outBand   = c('NDVI1',     'LAI1',      'TCI1',      'NDVI2',     'LAI2',      'TCI2')
  band      = c('NDVI2'),
  whichBand = c('NMAXNDVI2'),
  outBand   = c('NDVI2')
)
# processing block size (affects memory usage)
compositeBlockSize = 2048
# should already existing composite images be skipped (TRUE) or reprocessed anyway (FALSE)
compositeSkipExisting = TRUE

# ~~~~~~~~~~~~~~~~~ AGGREGATE

# bands to be aggregated into quantiles
#aggregateBands = c('NDVI2', 'NDTI2', 'MNDWI2', 'NDBI2', 'BSI2', 'BLFEI2')
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

# ~~~~~~~~~~~~~~~~~ TILE

tileRawBands = character()
tilePeriodBands = list(
#  '1 month' = c('LAI1', 'NDVI1', 'TCI1', 'LAI2', 'NDVI2', 'TCI2'),
  '1 month' = c('DOYMAXNDVI2', 'NMAXNDVI2', 'NDVI2'),
  '1 year' = c(
#    'DOYMAXNDVI2', 'NMAXNDVI2', 'DOYMAXNDVI1', 'NMAXNDVI1'
#    'N2',
#    'NDVI2q05',  'NDVI2q50',  'NDVI2q98',
#    'NDTI2q05',  'NDTI2q50',  'NDTI2q95', 
#    'MNDWI2q05', 'MNDWI2q50', 'MNDWI2q95', 
#    'NDBI2q05',  'NDBI2q50',  'NDBI2q95', 
#    'BSI2q05',   'BSI2q50',   'BSI2q95', 
#    'BLFEI2q05', 'BLFEI2q50', 'BLFEI2q95'
    'NDVI2q05',  'NDVI2q50',  'NDVI2q98'
  )
)
# should already existing tiles be skipped (TRUE) or reprocessed anyway (FALSE)
tileSkipExisting = TRUE
# reprojection resampling algorithm - see `man gdalwap``
tileResamplingMethod = 'near'
# additional gdalwarp parameters used while reprojection & retiling - see `man gdalwap``
tileGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'

# ~~~~~~~~~~~~~~~~~ OVERVIEW

# tiles to be merged into overviews
overviewPeriodBands = list(
#  '1 month' = c('LAI1',    'LAI2', 'NDVI1', 'NDVI2', 'TCI1', 'TCI2'),
  '1 month' = c('DOYMAXNDVI2', 'NMAXNDVI2', 'NDVI2'),
  '1 year'  = c('NDVI2q05', 'NDVI2q50', 'NDVI2q95')
)
overviewResolution = 100
overviewResamplingMethod = 'bilinear'
overviewGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'
overviewNCores = 16
overviewSkipExisting = TRUE
