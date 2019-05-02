#' Returns list of grid tiles matching a given roi and time span
#' @param gridFile file storing the tiling grid
#' @param roi region of interest id
#' @param dateFrom beginning of the time period (YYYY-MM-DD)
#' @param dateTo ending of the time period (YYYY-MM-DD)
#' @param bands vector of band names
#' @param user s2.boku.eodc.eu service user name
#' @param pswd s2.boku.eodc.eu service user password
#' @param tilesDir local tiles catalog location
#' @return data.frame listing the grid tiles (with column \code{date, band, tile & tileFile})
#' @export
#' @import dplyr
getTiles = function(gridFile, roi, dateFrom, dateTo, bands, user, pswd, tilesDir) {
  sentinel2::S2_initialize_user(user, pswd)
  projection = sf::st_crs(sf::st_read(gridFile, quiet = TRUE))
  tiles = suppressMessages(getImages(roi, dateFrom, dateTo, '', projection, 'SCL')) %>%
    mapRawTiles(gridFile) %>%
    dplyr::select(.data$date, .data$tile) %>%
    dplyr::distinct() %>%
    dplyr::mutate(x = 1) %>%
    dplyr::inner_join(dplyr::tibble(x = 1, band = bands)) %>%
    dplyr::select(-.data$x) %>%
    dplyr::mutate(tileFile = getTilePath(tilesDir, .data$tile, .data$date, .data$band)) %>%
    dplyr::arrange(.data$date, .data$band, .data$tile)
  return(tiles)
}
