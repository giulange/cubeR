#' Prepares raster file variants without information on the no data value
#' @details A simple VRT file if overridden nodata value is created so the
#' operation doesn't take time nor disk space.
#' @param files vector of raster file names to be processed
#' @param targetDir directory to store the processed files
#' @param prefix file name prefix of the processed files
#' @return vector of processed file names
#' @export
#' @import dplyr
preprocessNodata = function(files, targetDir, prefix = 'nodata_') {
  nodataFiles = paste0(targetDir, '/', prefix, basename(files), '.vrt')
  command = paste0('gdal_translate -a_nodata none -of vrt "', files, '" "', nodataFiles, '"')
  for (i in command) {
    system(i, ignore.stdout = TRUE)
  }
  return(nodataFiles)
}
