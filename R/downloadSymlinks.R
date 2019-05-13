#' "downloads" data by creating symlinks to the s2.boku.eodc.eu internal storage
#' @details
#' When running on EODC it doesn't make sense to really download the data.
#' Instead symlinks to the internal s2.boku.eodc.eu storage locations can be
#' created.
#' @param imageId vector of image IDs
#' @param conn s2.boku.eodc.eu DBI database connection
#' @param targetDir directory to "download" the data to
#' @param basePath base location of the s2.boku.eodc.eu storage
#' @return data frame describing "downloaded" data
#' @export
#' @import dplyr
downloadSymlinks = function(imageId, conn, targetDir, basePath = '/eodc/private/boku/sentinel2/GRANULES') {
  imageId = unique(imageId)
  query = sprintf(
    "SELECT granule_id, utm_id, date::date, band_id, filename FROM s2_images JOIN s2_granules USING (granule_id) WHERE image_id IN (%s)",
    paste0('$', seq_along(imageId), collapse = ', ')
  )
  symlinks = dplyr::as_tibble(DBI::dbGetQuery(conn, query, imageId))
  symlinks = symlinks %>%
    dplyr::mutate(
      filename = sprintf(
        '%s/%02d/%02d/%d/%s',
        basePath, floor(.data$granule_id / 100) %% 100, .data$granule_id %% 100, .data$granule_id, .data$filename
      ),
      tileFile = getTilePath(targetDir, .data$utm_id, .data$date, .data$band_id)
    ) %>%
    dplyr::mutate(
      srcExists = file.exists(.data$filename),
      targetExists = file.exists(.data$tileFile)
    )
  createDirs(symlinks$tileFile)
  tmp = symlinks %>%
    dplyr::filter(.data$srcExists & !.data$targetExists) %>%
    dplyr::mutate(
      success = file.symlink(.data$filename, .data$tileFile)
    )
  symlinks = symlinks %>%
    dplyr::left_join(tmp) %>%
    dplyr::mutate(
      success = dplyr::coalesce(.data$success, FALSE)
    )
  return(symlinks)
}
