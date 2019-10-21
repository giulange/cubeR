#' Returns local path for a given tile
#' @param targetDir local storage directory
#' @param tile tile name
#' @param date acquisition date
#' @param band band
#' @param ext file extension
#' @return character
#' @export
getTilePath = function(targetDir, tile, date, band, ext = 'tif') {
  return(sprintf('%s/%s/%s_%s_%s.%s', targetDir, tile, date, band, tile, ext))
}
