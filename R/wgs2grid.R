#' Computes WGS-84 point positions on a given raster grid
#' @param x vector of WGS-84 longitutes
#' @param y vector of WGS-84 latitudes
#' @param gridProjection raster grid projection (EPSG code)
#' @param tileSizeX raster grid tile size
#' @param tileSizeY raster grid tile size
#' @param originX coordinate (in raster grid projection) of a first grid tile
#' @param originY coordinate (in raster grid projection) of a first grid tile
#' @param resX resolution of a raster tile gird (in its native units)
#' @param resY resolution of a raster tile gird (in its native units)
#' @param template a \code{sprintf} function template used to generate the tile
#'   name (the x tile is passed as a first placeholder and the y tile as a
#'   second one - see the \code{sprintf} documentation to see how to swap the
#'   order)
#' @return list of data frames with columns \code{tile, px, py} indicating the tile name,
#'   and a pixel position
#' @export
wgs2grid = function(x, y, gridProjection = 3035, tileSizeX = 100000, tileSizeY = 100000, originX = 0, originY = 0, resX = 10, resY = -10, template = 'E%1$02dN%2$02d') {
  p = purrr::map2(x, y, function(a, b){
    sf::st_point(c(a, b))
  }) %>%
    sf::st_sfc(crs = 4326) %>%
    sf::st_transform(gridProjection)
  xx = as.numeric(purrr::map(p, function(x){x[1]}))
  yy = as.numeric(purrr::map(p, function(x){x[2]}))
  tx = as.integer((xx - originX) / tileSizeX)
  ty = as.integer((yy - originY) / tileSizeY)
  tile = sprintf(template, tx, ty)
  px = as.integer((xx - tileSizeX * tx) / resX)
  py = as.integer((yy - tileSizeY * ty) / resY)
  ret = dplyr::tibble(tile = tile, x = xx, y = yy, px = px, py = py) %>%
    dplyr::mutate(
      px = dplyr::if_else(.data$px < 0L, as.integer(tileSizeX / -resX) + .data$px - 1L, .data$px),
      py = dplyr::if_else(.data$py < 0L, as.integer(tileSizeY / -resY) + .data$py - 1L, .data$py)
    ) %>%
    dplyr::group_by(dplyr::row_number()) %>%
    tidyr::nest()
  return(ret$data)
}