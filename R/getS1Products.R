#' Fetches list of S1 products
#' @param roiId an id of a region of interest which to be fetched
#' @param dateMin minimum acquisition date of an image
#' @param dateMax maximum acquisition date of an image
#' @param dir a target directory (although this function doesn't download files
#'   it creates target file paths)
#' @param projection a projection of the returned product extents
#' @return data frame describing matching S1 products
#' @import dplyr
#' @export
getS1Products = function(roiId, dateMin, dateMax, dir, projection) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }

  dirDict = c('desc', 'asc')
  products = sentinel2:::S2_do_query(list(regionId = roiId, product = '%_GRD%', dateMin = dateMin, dateMax = dateMax), '/s1') %>%
    dplyr::filter(!is.na(url)) %>%
    dplyr::mutate(geometry = sentinel2:::geojson_to_geometry(geometry, 'sf')) %>%
    dplyr::mutate(geometry = purrr::map(geometry, sf::st_transform, projection)) %>%
    dplyr::group_by(date, asc) %>%
    dplyr::mutate(
      file = sprintf('%s/%s.zip', dir, product)
    ) %>%
    dplyr::ungroup()
  return(products)
}
