args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath user pswd regionId dateFrom dateTo')
}
cat(c('Running dwnld.R', args, as.character(Sys.time()), '\n'))
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
toGo = images %>%
    arrange(desc(date), utm, band) %>%
    select(url, file)
while (nrow(toGo) > 0) {
  cat(sprintf('%d/%d (%d%%) %s\n', nrow(images) - nrow(toGo), nrow(images), as.integer(100 * (nrow(images) - nrow(toGo)) / nrow(images)), Sys.time()))
  results = foreach(url = toGo$url, file = toGo$file, .combine = c) %dopar% {
    cat(file, '\n')
    try(sentinel2::S2_download(url, file, progressBar = FALSE, skipExisting = dwnldSkipExisting, timeout = dwnldTimeout, tries = dwnldTries, zip = FALSE), silent = TRUE)
  }
  toGo = toGo[!results, ]
}
cat(sprintf('%d/%d (100%%) %s\n', nrow(images), nrow(images), Sys.time()))
