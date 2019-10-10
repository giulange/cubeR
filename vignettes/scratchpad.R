devtools::load_all()

# don't forget to adjust the config file content
packageDir = '~/roboty/BOKU/cube/cubeR'
cfgFile = "~/roboty/BOKU/cube/cubeR/scripts/config/configZozlak.R"
s2user = "zozlak"
s2pswd = "xxx"
s2roi = "_33UXP"
dateStart = "2018-03-01"
dateEnd = "2018-04-30"

# init
system(paste('Rscript', paste0(packageDir, '/scripts/init.R'), cfgFile, s2roi, dateStart, dateEnd, s2user, s2pswd))
# download
system(paste('Rscript', paste0(packageDir, '/scripts/dwnld.R'), cfgFile, s2roi, dateStart, dateEnd))
# prepare cloud masks
system(paste('Rscript', paste0(packageDir, '/scripts/mask.R'), cfgFile, s2roi, dateStart, dateEnd))
# compute indicators
system(paste('Rscript', paste0(packageDir, '/scripts/indicator.R'), cfgFile, s2roi, dateStart, dateEnd))
# compute dates with max NDVI for monthly periods
system(paste('Rscript', paste0(packageDir, '/scripts/which.R'), cfgFile, s2roi, dateStart, dateEnd, shQuote('1 month')))
# prepare composites based on previously computed monthly max NDVI dates
system(paste('Rscript', paste0(packageDir, '/scripts/composite.R'), cfgFile, s2roi, dateStart, dateEnd, shQuote('1 month')))
# prepare yearly aggregates base on on previously computed yearly max NDVI dates
system(paste('Rscript', paste0(packageDir, '/scripts/aggregate.R'), cfgFile, s2roi, dateStart, dateEnd, shQuote('1 year')))
# reproject & retile
system(paste('Rscript', paste0(packageDir, '/scripts/tile.R'), cfgFile, s2roi, dateStart, dateEnd))
