#' Fetches list of images
#' @param roiId an id of a region of interest which to be fetched
#' @param dateMin minimum acquisition date of an image
#' @param dateMax maximum acquisition date of an image
#' @param dir a target directory (although this function doesn't download files
#'   it creates target file paths) - each UTM tile is placed in its own
#'   subdirectory
#' @param projection a projection of the returned images extent
#' @param bands list of bands to be fetched
#' @param ... another parameters to be passed to the
#'   \code{\link[sentinel2]{S2_query_image}}
#' @return data frame describing matching images
#' @import dplyr
#' @export
getImages = function(roiId, dateMin, dateMax, dir, projection, bands = c('B02', 'B03', 'B04', 'B05', 'B06', 'B07', 'B08', 'B8A', 'B11', 'B12', 'TCI', 'LAI', 'FAPAR', 'FCOVER', 'SCL'), ...) {
  granules = sentinel2::S2_query_granule(regionId = roiId, dateMin = dateMin, dateMax = dateMax, atmCorr = TRUE, owned = TRUE, spatial = 'sf') %>%
    dplyr::select(granuleId, geometry) %>%
    dplyr::mutate(geometry = purrr::map(geometry, sf::st_transform, projection))
  imgs = dplyr::as.tbl(sentinel2::S2_query_image(regionId = roiId, dateMin = dateMin, dateMax = dateMax, atmCorr = TRUE, owned = TRUE, ...))
  imgs = imgs %>%
    dplyr::group_by(granuleId, band) %>%
    dplyr::filter(band %in% bands & resolution == min(resolution)) %>%
    dplyr::group_by(granuleId) %>%
    dplyr::filter(n() == length(bands)) %>%
    dplyr::ungroup() %>%
    dplyr::inner_join(granules) %>%
    dplyr::mutate(date = substr(date, 1, 10)) %>%
    dplyr::mutate(file = sprintf('%s/%s/%s_%s_%s.tif', dir, utm, date, band, utm))

  for (i in unique(dirname(imgs$file))) {
    dir.create(i, recursive = TRUE, showWarnings = FALSE)
  }
  return(imgs)
}
