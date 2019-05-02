#' Returns local path for a given tile
#' @param targetDir local storage directory
#' @param tile tile name
#' @param date acquisition date
#' @param band band
#' @return character
#' @export
getTilePath = function(targetDir, tile, date, band) {
  return(sprintf('%s/%s/%s_%s_%s.tif', targetDir, tile, date, band, tile))
}
