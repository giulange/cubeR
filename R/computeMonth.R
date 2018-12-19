# computeMonth = function(cubeName, date, dir = '~/roboty/BOKU/cube/data', bands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER'), ...) {
#   dateMin = paste0(substr(date, 1, 7), '-01')
#   dateMax = as.POSIXlt(dateMin)
#   dateMax$mon = dateMax$mon + 1
#   dateMax = substr(as.character(dateMax - 1), 1, 10)
#
#   bands = unique(c(bands, 'SCL'))
#   imgs = downloadData(cubeName, dateMin, dateMax, paste0(dir, '/raw'), bands = bands, ...)
# }
