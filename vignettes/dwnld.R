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
cat('Downloading\n')
options(cores = dwnldNCores)
results = rep(FALSE, nrow(images))
while (!all(results)) {
  cat(sprintf('%d/%d (%d%%) %s\n', sum(results), length(results), 100 * sum(results) / length(results), Sys.time()))
  results = foreach(url = images$url, file = images$file, .combine = c) %dopar% {
    try(sentinel2::S2_download(url, file, progressBar = FALSE, skipExisting = dwnldSkipExisting, timeout = dwnldTimeout, tries = dwnldTries), silent = TRUE)
  }
}
cat(sprintf('%d/%d (%d%%) %s\n', sum(results), length(results), 100 * sum(results) / length(results), Sys.time()))
