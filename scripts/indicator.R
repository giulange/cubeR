args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(paste0(c('Running indicator.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

ind = indicatorsToTibble(indicatorIndicators)

tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
    imagesToTiles(rawDir, unique(ind$band)) %>%
    group_by(date, tile)
)
checkTilesExist(tiles)

nOut = tiles %>% select(tile, date) %>% nrow() *  n_distinct(ind$name)
cat(paste('Computing', nOut, 'indicator images for', n_distinct(tiles$tile, tiles$date), 'tileDates', Sys.time(), '\n'))
options(cores = nCores)
images = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  # grouping by date & tile only assures effective usage and lack of conflicts of temporary resampled bands
  tmp = tls %>% select(date, tile) %>% distinct()
  cat(paste(tmp$date, tmp$tile, collapse = ', '), ' (', nrow(tmp), ')\n', sep = '')

  suppressMessages(prepareIndicators(tls, rawDir, tmpDir, ind, skipExisting = indicatorSkipExisting))
}
logProcessingResults(images, t0)
