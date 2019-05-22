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
library(doParallel, quietly = TRUE)
registerDoParallel()

grid = sf::read_sf(gridFile, quiet = TRUE)
S2_initialize_user(args['user'], args['pswd'])
regionFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands, 'geojson')
region = sf::st_read(regionFile, quiet = TRUE) %>%
  sf::st_transform(sf::st_crs(grid))
tiles = grid$TILE[sf::st_intersects(grid, region, sparse = FALSE)]

images = c()
for (tile in tiles) {
  images = append(images, list.files(paste0(tilesDir, '/', tile), 'tif$'))
}
images = tibble(tileFile = images) %>%
  tidyr::separate(tileFile, c('period', 'band', 'tile', 'ext'), '[_.]', remove = FALSE, extra = 'drop', fill = 'left') %>%
  filter(period >= args['from'] & period <= args['to'] & band %in% overviewBands) %>%
  mutate(
    tileFile = paste0(tilesDir, '/', tile, '/', tileFile)
  ) %>%
  mutate(
    tile = sub('_', '-', args['region']),
  ) %>%
  group_by(period, band)

cat(paste('Creating', n_groups(images), 'overviews', Sys.time(), '\n'))
options(cores = nCores)
overviews = foreach(tls = assignToCores(images, nCores, chunksPerCore), .combine = bind_rows) %dopar% {
  tmp = tls %>% select(period, band, tile) %>% distinct()
  cat(paste(tmp$period, tmp$band, collapse = ', '), ' (', n_groups(tls), ')\n', sep = '')

  suppressMessages(prepareOverviews(tls, overviewsDir, tmpDir, overviewResolution, overviewResamplingMethod, skipExisting = overviewSkipExisting, gdalOpts = overviewGdalOpts))
}
logProcessingResults(overviews, t0)
