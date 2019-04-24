args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
source(args[1])

devtools::load_all(cubeRpath)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE)

S2_initialize_user(args[2], args[3])
projection = sf::st_crs(sf::st_read(gridFile))

images = getImages(args[4], args[5], args[6], rawDir, projection, bands)
sentinel2::S2_download(images$url, images$file)

tiles = images %>%
  group_by(date, band) %>%
  do({
    tilesTmp = prepareTiles(., tilesDir, gridFile, tmpDir, resamplingMethod)
    tilesTmp %>%
      select(-date, -band)
  })
