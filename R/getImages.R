#' Fetches list of images
#' @param roiId an id of a region of interest which to be fetched
#' @param dateMin minimum acquisition date of an image
#' @param dateMax maximum acquisition date of an image
#' @param cloudCovMax maximum accepted cloud coverage (from 0 to 1)
#' @param dir a target directory (although this function doesn't download files
#'   it creates target file paths) - each UTM tile is placed in its own
#'   subdirectory
#' @param bandsS2 list of Sentinel-2 bands to be fetched
#' @param user s2.boku.eodc.eu service user name
#' @param pswd s2.boku.eodc.eu service user password
#' @param cache should locally cached data be used when available (and should
#'   local cache be written)
#' @param ... another parameters to be passed to the
#'   \code{\link[sentinel2]{S2_query_image}}
#' @return data frame describing matching images
#' @import dplyr
#' @export
getImages = function(roiId, dateMin, dateMax, cloudCovMax, dir, bandsS2, user = NULL, pswd = NULL, cache = TRUE, ...) {
  cacheFile = sprintf('%s_%s_%s_%s_%s.RData', roiId, dateMin, dateMax, cloudCovMax, paste0(bandsS2, collapse = '_'))
  if (cache & file.exists(cacheFile)) {
    load(cacheFile)
    createDirs(imgs$file)
    return(imgs)
  }

  if (!is.null(user) & !is.null(pswd)) {
    sentinel2::S2_initialize_user(user, pswd)
  }

  imgs = dplyr::as.tbl(sentinel2::S2_query_image(regionId = roiId, dateMin = dateMin, dateMax = dateMax, cloudCovMin = 0, cloudCovMax = cloudCovMax * 100, atmCorr = TRUE, owned = TRUE, ...))
  imgs = imgs %>%
    dplyr::rename(dateFull = .data$date) %>%
    dplyr::mutate(date = substr(.data$dateFull, 1, 10)) %>%
    dplyr::group_by(.data$granuleId, .data$band) %>%
    dplyr::filter(.data$band %in% bandsS2 & .data$resolution == min(.data$resolution)) %>%
    dplyr::group_by(.data$granuleId) %>%
    dplyr::filter(n() == length(bandsS2)) %>%
    dplyr::group_by(.data$date, .data$utm, .data$band) %>% # same S2 acquisition (date x utm) can be received by two ground stations resulting in two granules (sic!)
    dplyr::filter(.data$dateFull == max(.data$dateFull)) %>%
    dplyr::select(-.data$dateFull) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(file = getTilePath(dir, .data$utm, .data$date, .data$band))

  createDirs(imgs$file)

  save(imgs, file = cacheFile)

  return(imgs)
}
