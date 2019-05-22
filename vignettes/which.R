args = commandArgs(TRUE)
if (length(args) < 5) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo period')
}
names(args) = c('cfgFile', 'region', 'from', 'to', 'period')
t0 = Sys.time()
cat(paste0(c('Running which.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
    imagesToTiles(rawDir, whichBands) %>%
    mapTilesPeriods(args['period'], args['from']) %>%
    group_by(period, tile, band) %>%
    arrange(period, tile, date, band)
)
if (!all(file.exists(tiles$tileFile))) {
  stop('missing tiles')
}

cat(paste('Computing', n_groups(tiles), 'which images', Sys.time(), '\n'))
options(cores = nCores)
which = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')

  suppressMessages(prepareWhich(tls, periodsDir, tmpDir, paste0(cubeRpath, '/python'), whichPrefix, whichSkipExisting, whichBlockSize))
}
logProcessingResults(which, t0)
