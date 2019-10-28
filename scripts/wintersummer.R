args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running wintersummer.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr, quietly = TRUE)
library(doParallel, quietly = TRUE)

registerDoParallel()
options(cores = nCores)

images = getCache(args['region'], args['from'], args['to'], args['cfgFile'])

# model
regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
results = prepareWinterSummerModel(
  images, periodsDir, modelsDir, tmpDir, regionFile, lcFile, wintersummerClimateFiles,
  wintersummerDoyBand, wintersummerNdviMaxBand, wintersummerModelName, wintersummerNdviMin,
  wintersummerResamplingMethod, wintersummerSkipExisting, wintersummerGdalOpts
)
logProcessingResults(results %>% rename(tileFile = coefFile), t0)
t1 = Sys.time()

# threshold band
thresholdBand = paste0(wintersummerModelName, 'TH')
tiles = images %>%
  imagesToTiles(periodsDir, thresholdBand) %>%
  mapTilesPeriods('1 year') %>%
  select(period, tile) %>%
  distinct() %>%
  mutate(
    modelFile = getTilePath(modelsDir, wintersummerModelName, period, 'COEF', ext = 'csv'),
    lcFile = getTilePath(rawDir, tile, '1900-01-01', wintersummerLcBand)
  )
for (i in seq_along(wintersummerClimateFiles)) {
  tmp = paste0(names(wintersummerClimateFiles)[i], 'File')
  tiles = tiles %>%
    mutate(!!tmp := getTilePath(rawDir, tile, '1900-01-01', names(wintersummerClimateFiles)[i]))
}
checkTilesExist(tiles %>% tidyr::gather(key = 'type', value = 'tileFile', -.data$period, -.data$tile))
results = prepareWinterSummerThresholds(tiles, periodsDir, tmpDir, thresholdBand, wintersummerSkipExisting)
logProcessingResults(results, t1)
t2 = Sys.time()

# winter/summer band
tiles = images %>%
  imagesToTiles(periodsDir, thresholdBand) %>%
  mapTilesPeriods('1 year') %>%
  select(period, tile) %>%
  distinct() %>%
  mutate(
    thresholdFile = getTilePath(periodsDir, tile, period, thresholdBand),
    doyFile = getTilePath(periodsDir, tile, period, wintersummerDoyBand)
  )
checkTilesExist(tiles %>% tidyr::gather(key = 'type', value = 'tileFile', -.data$period, -.data$tile))
results = prepareWinterSummer(tiles, periodsDir, tmpDir, wintersummerModelName, wintersummerSkipExisting)
logProcessingResults(results, t2)
