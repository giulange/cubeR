devtools::load_all()
library(dplyr)

# don't forget to adjust the config file content
packageDir = '~/roboty/BOKU/cube/cubeR'
cfgFile = "~/roboty/BOKU/cube/cubeR/vignettes/configZozlak.R"
s2user = "zozlak"
s2pswd = "alamakota"
s2roi = "AU_cube"
dateStart = "2018-05-01"
dateEnd = "2018-05-31"

# download
system(paste('Rscript', paste0(packageDir, '/vignettes/dwnld.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd))
# reproject & retile
system(paste('Rscript', paste0(packageDir, '/vignettes/tile.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd))
# prepare cloud masks
system(paste('Rscript', paste0(packageDir, '/vignettes/mask.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd))
# compute NDVI
system(paste('Rscript', paste0(packageDir, '/vignettes/ndvi.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd))
# compute dates with max NDVI for monthly periods
period = '1 month'
system(paste('Rscript', paste0(packageDir, '/vignettes/which.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd, shQuote(period)))
# prepare composites based on previously computed max NDVI dates
period = '1 month'
maxNdviBand = 'NMAXNDVI'
system(paste('Rscript', paste0(packageDir, '/vignettes/composite.R'), cfgFile, s2user, s2pswd, s2roi, dateStart, dateEnd, shQuote(period), maxNdviBand))
