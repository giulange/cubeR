cubeRpath = '/eodc/private/boku/software/cubeR'
gridFile = '/eodc/private/boku/ACube2/shapes/EQUI7_V13_EU_PROJ_TILE_T1.shp'
tmpDir = '/eodc/private/boku/ACube2/tmp'
rawDir = '/eodc/private/boku/ACube2/raw'
periodsDir = '/eodc/private/boku/ACube2/periods'
tilesDir = '/eodc/private/boku/ACube2/tiles'
overviewsDir = '/eodc/private/boku/ACube2/overviews'
cacheTmpl = '/eodc/private/boku/ACube2/cache/{region}_{dateFrom}_{dateTo}_{cloudCovMax}_{bands}'
acubeDir = '/eodc/private/boku/ACube'

bands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL')
cloudCov = 0.5
nCores = 14
chunksPerCore = 10

dwnldMethod = 'symlink'
dwnldMaxRemovals = 100
dwnldDbParam = list(host = '10.250.16.131', port = 5432, user = 'eodc', dbname = 'bokudata')
dwnldNCores = 4
dwnldTimeout = 120
dwnldSkipExisting = 'samesize'
dwnldTries = 2

maskParam = list(
  list(bandName = 'CLOUDMASK2', minArea = 0L, bufferSize = 0L, invalidValues = c(0L:3L, 7L:11L), bufferedValues = integer())
)
maskSkipExisting = TRUE

indicatorIndicators = list(
  list(bandName = 'NDVI2',  resolution = 10, mask = 'CLOUDMASK2', factor = 10000, bands = c('A' = 'B08', 'B' = 'B04'), equation = '(A.astype(float) - B) / (0.0000001 + A + B)')
)
indicatorSkipExisting = TRUE

whichBands = c('NDVI2')
whichPrefix = 'NMAX'
whichDoyPrefix = 'DOYMAX'
whichBlockSize = 1024
whichSkipExisting = TRUE

compositeBands = list(
  band      = c('B02',       'B03',       'B04',       'B05',       'B06',       'B07',       'B08',       'B8A',       'B11',       'B12',       'TCI',       'LAI',       'FAPAR',     'FCOVER'),
  whichBand = c('NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2', 'NMAXNDVI2'),
  outBand   = c('B02',       'B03',       'B04',       'B05',       'B06',       'B07',       'B08',       'B8A',       'B11',       'B12',       'TCI2',      'LAI2',      'FAPAR2',    'FCOVER2')
)
compositeBlockSize = 1024
compositeSkipExisting = TRUE

tileRawBands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK2')
tilePeriodBands = list(
  '1 month' = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI2', 'LAI2', 'FAPAR2', 'FCOVER2', 'NMAXNDVI2')
)
tileResamplingMethod = 'near'
tileGdalOpts = '--config GDAL_CACHEMAX 4096 -multi -wo NUM_THREADS=2 -co "COMPRESS=DEFLATE" -co "TILED=YES" -co "BLOCKXSIZE=512" -co "BLOCKYSIZE=512"'
tileSkipExisting = TRUE

renameBands = data.frame(
  band =   c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK2', 'B02',  'B03',  'B04',  'B05',  'B06',  'B07',  'B08',  'B8A',  'B11',  'B12',  'TCI2', 'LAI2', 'FAPAR2', 'FCOVER2'),
  name =   c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL', 'CLOUDMASK',  'MB02', 'MB03', 'MB04', 'MB05', 'MB06', 'MB07', 'MB08', 'MB8A', 'MB11', 'MB12', 'MTCI', 'MLAI', 'MFAPAR', 'MFCOVER'),
  type =   c('',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',    '',      '',       '',    '',           'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',    'm',   'm',    'm',      'm'),
  #                   bands,  TCI,      LAI/etc.,   SCL, CLOUD,         mBands,  mTCI,     mLAI/etc.
  scale =  c(rep(10000, 10),   NA,  rep(1000, 3),    NA,    NA, rep(10000, 10),    NA,  rep(1000, 3)),
  nodata = c(rep(65535, 10),  255, rep(32767, 3),     0,   255, rep(65534, 10),   255, rep(32767, 3)),
  mask =   c( rep(TRUE, 10), TRUE,  rep(TRUE, 3), FALSE, FALSE, rep(FALSE, 10), FALSE, rep(FALSE, 3))
)
