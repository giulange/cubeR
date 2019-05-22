#' Maps raw images to the grid
#' @param input data frames describing tiles to be mapped to the grid (must
#'   contain \code{tileFile})
#' @param gridFile file with a grid (with tile name in the \code{TILE} feature
#'   property)
#' @param regionFile region extent file (because it can be smaller than union of
#'   all tiles)
#' @return \code{input} data frame extended with \code{tile} & \code{bbox}
#'   columns
#' @import dplyr
#' @export
mapTilesGrid = function(input, gridFile, regionFile = NULL) {
  grid = sf::read_sf(gridFile, quiet = TRUE)
  projection = sf::st_crs(grid)
  if (!is.null(regionFile)) {
    region = sf::read_sf(regionFile, quiet = TRUE) %>%
      sf::st_transform(projection)
    grid = grid %>%
      dplyr::filter(sf::st_intersects(grid, region, sparse = FALSE))
  }

  gridBbox = dplyr::tibble(
    tile = grid$TILE,
    bbox = purrr::map(grid$geometry, sf::st_bbox)
  ) %>%
    dplyr::mutate(bbox = purrr::map_chr(.data$bbox, paste, collapse = ' '))

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
