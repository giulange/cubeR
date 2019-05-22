args = commandArgs(TRUE)
if (length(args) < 6) {
  stop('This scripts takes parameters: settingsFilePath regionId dateFrom dateTo user pswd')
}
names(args) = c('cfgFile', 'region', 'from', 'to', 'user', 'pswd')
cat(paste0(c('Running init.R', args, as.character(Sys.time()), '\n'), collapse = '\t'))
source(args[1])

devtools::load_all(cubeRpath, quiet = TRUE)
library(sentinel2, quietly = TRUE)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)

S2_initialize_user(args['user'], args['pswd'])
images = getImages(args['region'], args['from'], args['to'], cloudCov, rawDir, bands)
cacheFile = getCachePath(cacheTmpl, args['region'], args['from'], args['to'], cloudCov, bands)
invisible(createDirs(cacheFile))
write.csv(images, cacheFile, row.names = FALSE)

cat(sprintf('%d\timages\t%s\n', nrow(images), Sys.time()))
