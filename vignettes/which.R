args = commandArgs(TRUE)
if (length(args) < 7) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo period')
}
names(args) = c('cfgFile', 'user', 'pswd', 'region', 'from', 'to', 'period')
cat(c('Running which.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, gridFile, bands, args['user'], args['pswd']) %>%
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

  suppressMessages(prepareWhich(tls, rawDir, tmpDir, paste0(cubeRpath, '/python'), whichPrefix, whichSkipExisting, whichBlockSize))
}
cat(paste(nrow(which), 'which images produced', Sys.time(), '\n'))
