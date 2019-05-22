args = commandArgs(TRUE)
if (length(args) < 4) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo')
}
names(args) = c('cfgFile', 'region', 'from', 'to')
t0 = Sys.time()
cat(c('Running overview.R', args, as.character(Sys.time()), '\n'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr, quietly = TRUE)
library(doParallel, quietly = TRUE)
registerDoParallel()

grid = sf::read_sf(gridFile, quiet = TRUE)
regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
region = sf::st_read(regionFile, quiet = TRUE) %>%
  sf::st_transform(sf::st_crs(grid))
tiles = grid$TILE[sf::st_intersects(grid, region, sparse = FALSE)]

# prepare filters
dates = tibble(period = character())
for (i in names(overviewPeriodBands)) {
  dates = tibble(x = c('from', 'to'), date = c(args['from'], args['to'])) %>%
    mapTilesPeriods(i, args['from']) %>%
    mutate(
      date = period,
      period = i
    ) %>%
    spread(x, date) %>%
    bind_rows(dates)
}
periodsBands = suppressMessages(
  tibble(period = names(overviewPeriodBands), band = overviewPeriodBands) %>%
    unnest() %>%
    inner_join(dates) %>%
    mutate(period = sub('^[0-9]+(-[0-9]+)?(-[0-9]+)?', '', from))
)

# get available data
images = c()
for (tile in tiles) {
  images = append(images, list.files(paste0(tilesDir, '/', tile), 'tif$', full.names = TRUE))
}
images = suppressMessages(
  tibble(tileFile = images) %>%
    mutate(tmp = basename(tileFile)) %>%
    separate(tmp, c('date', 'band', 'tile', 'ext'), '[_.]', extra = 'drop', fill = 'left') %>%
    mutate(
      period = sub('^[0-9]+(-[0-9]+)?(-[0-9]+)?', '', date),
      tile = sub('_', '-', args['region']),
    ) %>%
    inner_join(periodsBands) %>%
    filter(date >= from & date <= to) %>%
    group_by(tile, date, band)
)

cat(paste('Creating', n_groups(images), 'overviews', Sys.time(), '\n'))
options(cores = nCores)
overviews = foreach(tls = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(date, band, tile) %>% distinct()
  cat(paste(tmp$date, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')

  suppressMessages(prepareOverviews(tls, overviewsDir, tmpDir, overviewResolution, overviewResamplingMethod, skipExisting = overviewSkipExisting, gdalOpts = overviewGdalOpts))
}
logProcessingResults(overviews, t0)
