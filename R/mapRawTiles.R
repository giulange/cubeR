#' Maps raw images to the grid
#' @param images data frame describing raw images. Must contain (at least)
#'   \code{date, band, file} columns
#' @param gridFile file with a grid (with tile name in the \code{TILE} feature
#'   property)
#' @return \code{images} data frame extended with \code{tile} and \code{bbox}
#'   columns (containng the tile name and the tile bounding box). It is likely
#'   it has more rows than the \code{images} data frame as one raw image can
#'   intersect many grid tiles.
#' @import dplyr
#' @export
mapRawTiles = function(images, gridFile) {
  grid = sf::read_sf(gridFile, quiet = TRUE)
  gridBbox = dplyr::tibble(
    tile = grid$TILE,
    bbox = purrr::map(grid$geometry, sf::st_bbox)
  ) %>%
    dplyr::mutate(bbox = purrr::map_chr(.data$bbox, paste, collapse = ' '))

  tiles = images %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      tile = purrr::map(.data$geometry, function(x){
        grid$TILE[sf::st_intersects(grid, x, sparse = FALSE)]
      })
    ) %>%
    tidyr::unnest(.data$tile) %>%
    dplyr::inner_join(gridBbox)
  return(tiles)
}
