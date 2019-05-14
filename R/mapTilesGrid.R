#' Maps raw images to the grid
#' @param input data frames describing tiles to be mapped to the grid (must
#'   contain \code{tileFile})
#' @param gridFile file with a grid (with tile name in the \code{TILE} feature
#'   property)
#' @return \code{input} data frame extended with \code{tile} & \code{bbox}
#'   columns
#' @import dplyr
#' @export
mapTilesGrid = function(input, gridFile) {
  grid = sf::read_sf(gridFile, quiet = TRUE)
  gridBbox = dplyr::tibble(
    tile = grid$TILE,
    bbox = purrr::map(grid$geometry, sf::st_bbox)
  ) %>%
    dplyr::mutate(bbox = purrr::map_chr(.data$bbox, paste, collapse = ' '))
  projection = sf::st_crs(grid)

  result = input %>%
    dplyr::mutate(
      geom = purrr::map(.data$tileFile, function(x){sf::st_transform(sf::st_as_sfc(sf::st_bbox(raster::raster(x))), projection)})
    ) %>%
    dplyr::mutate(
      tile = purrr::map(.data$geom, function(x){grid$TILE[sf::st_intersects(grid, x, sparse = FALSE)]})
    ) %>%
    dplyr::select(-.data$geom) %>%
    tidyr::unnest() %>%
    dplyr::inner_join(gridBbox)
  return(result)
}
