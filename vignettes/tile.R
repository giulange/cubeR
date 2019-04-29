args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
source(args[1])

devtools::load_all(cubeRpath)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE)
library(doParallel, quietly = TRUE)

registerDoParallel()

S2_initialize_user(args[2], args[3])
projection = sf::st_crs(sf::st_read(gridFile))
images = getImages(args[4], args[5], args[6], rawDir, projection, bands) %>%
  arrange(date, band)
if (!all(file.exists(images$file))) {
  stop('raw file missing - run dwnld.R first')
}

cat(paste('Tiling', nrow(images), 'images', Sys.time(), '\n'))
groups = images %>%
  select(date, band) %>%
  arrange(desc(date), band) %>%
  distinct()
options(cores = nCores)
tiles = foreach(dt = groups$date, bnd = groups$band, .combine = bind_rows) %dopar% {
  tilesTmp = images %>%
    filter(date == dt & band == bnd) %>%
    mapRawTiles(gridFile) %>%
    prepareTiles(tilesDir, gridFile, tmpDir, resamplingMethod, tilesSkipExisting)
  tilesTmp
}
cat(paste(nrow(tiles), 'tiles produced', Sys.time(), '\n'))
