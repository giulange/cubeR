args = commandArgs(TRUE)
if (length(args) < 5) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo period')
}
names(args) = c('cfgFile', 'region', 'from', 'to', 'period')
t0 = Sys.time()
cat(paste0(c('Running aggregate.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(doParallel, quietly = TRUE)
registerDoParallel()

tiles = suppressMessages(
  getCache(args['region'], args['from'], args['to'], args['cfgFile']) %>%
    imagesToTiles(rawDir, aggregateBands) %>%
    mapTilesPeriods(args['period'], args['from']) %>%
    group_by(period, tile, band) %>%
    arrange(period, tile, band, date)
)
checkTilesExist(tiles)

options(cores = nCores)
cat(paste('Computing', n_groups(tiles), 'aggregates', Sys.time(), '\n'))
aggregates = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, tile, band) %>% distinct()
  cat(paste(tmp$period, tmp$tile, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')
  suppressMessages(prepareQuantiles(tls, periodsDir, tmpDir, paste0(cubeRpath, '/python'), aggregateQuantiles, aggregateSkipExisting, aggregateBlockSize))
}
logProcessingResults(aggregates, t0)

t0 = Sys.time()
if (aggregateCounts) {
  tiles = tiles %>%
    ungroup %>%
    filter(band == aggregateCountsBand) %>%
    group_by(period, tile)
  cat(paste('Computing', n_groups(tiles), 'counts', Sys.time(), '\n'))
  counts = foreach(tls = assignToCores(tiles, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
    tmp = tls %>% select(period, tile) %>% distinct()
    cat(paste(tmp$period, tmp$tile, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')
    suppressMessages(prepareCounts(tls, periodsDir, tmpDir, paste0(cubeRpath, '/python'), aggregateCountsOutBand, aggregateSkipExisting, aggregateBlockSize))
  }
  logProcessingResults(counts, t0)
}
