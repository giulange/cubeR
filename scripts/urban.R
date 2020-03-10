args = commandArgs(TRUE)
args = c("/eodc/private/boku/software/cubeR/scripts/config/configEodc.R", "_33UXP", "2018-03-01", "2018-04-30")
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running urban.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr, quietly = TRUE)
library(doParallel, quietly = TRUE)
library(randomForest)

registerDoParallel()
options(cores = nCores)

images = getCache(args['region'], args['from'], args['to'], args['cfgFile'])
regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
# ugly because Francesco implemented it on the target grid (sic!)
tilesList = suppressMessages(
  images %>%
    filter(band == first(band)) %>%
    group_by(utm) %>%
    filter(date == first(date)) %>%
    ungroup() %>%
    rename(tileFile = file) %>%
    mapTilesGrid(gridFile, regionFile) %>%
    select(tile) %>%
    distinct()
)
# here and now models are precomputed (sic!)
models = tibble(modelFile = list.files(urbanModelsDir, '^rfmod_', full.names = TRUE)) %>%
  mutate(tile = sub('^.*_([^.]+)[.]R$', '\\1', modelFile))
tiles = suppressMessages(
  images %>%
    imagesToPeriods('1 year', periodsDir, urbanIndicators) %>%
    select(-tile) %>%
    distinct() %>%
    mutate(x = 1L) %>%
    inner_join(tilesList %>% mutate(x = 1L)) %>%
    select(-x) %>%
    inner_join(models) %>%
    mutate(tileFile = getTilePath(tilesDir, tile, period, band))
)
checkTilesExist(tiles) # modelFile is read from disk so no need to check it

results = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  prepareUrban(tls, tilesDir, tmpDir, urbanBand, urbanGdalOpts, skipExisting = urbanSkipExisting)
}
logProcessingResults(results, t0)
