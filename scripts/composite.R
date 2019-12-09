args = commandArgs(TRUE)
if (length(args) < 5) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo period')
}
names(args) = c('cfgFile', 'region', 'from', 'to', 'period')
t0 = Sys.time()
cat(paste0(c('Running composite.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

compositeBands = tibble(band = compositeBands$band, whichBand = compositeBands$whichBand, outBand = compositeBands$outBand)
tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
    imagesToTiles(rawDir, unique(compositeBands$band)) %>%
    mapTilesPeriods(args['period'], args['from']) %>%
    left_join(compositeBands) %>%
    mutate(
      inBand = .data$band,
      band = .data$outBand,
      whichFile = getTilePath(periodsDir, tile, period, whichBand)
    ) %>%
    group_by(period, tile, band) %>%
    arrange(period, tile, band, date)
)
tmp = tibble(tileFile = c(tiles$tileFile, unique(tiles$whichFile)))
checkTilesExist(tmp)

cat(paste('Computing', n_groups(tiles), 'composites', Sys.time(), '\n'))
options(cores = nCores)
composites = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')

  suppressMessages(prepareComposites(tls, periodsDir, tmpDir, paste0(cubeRpath, '/python'), compositeSkipExisting, compositeBlockSize))
}
logProcessingResults(composites, t0)
