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
cat('Downloading', nrow(images), 'files')
options(cores = dwnldNCores)
tmp = foreach(url = images$url, file = images$file, .combine = c) %dopar% {
  n = 0
  while (!file.exists(file) | file.size(file) == 0) {
    n = n + 1
    try(sentinel2::S2_download(url, file, skipExisting = dwnldSkipExisting, progressBar = FALSE, timeout = dwnldTimeout), silent = TRUE)
  }
  n
}

groups = images %>%
  select(date, band) %>%
  distinct()
options(cores = nCores)
tiles = foreach(dt = groups$date, bnd = groups$band, .combine = bind_rows) %dopar% {
  tilesTmp = images %>%
    filter(date == dt & band == bnd) %>%
    prepareTiles(tilesDir, gridFile, tmpDir, resamplingMethod) %>%
    select(-date, -band)
  tilesTmp
}
