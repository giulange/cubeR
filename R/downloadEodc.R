#' "downloads" data by creating symlinks to the s2.boku.eodc.eu internal storage
#' @details
#' When running on EODC it doesn't make sense to really download the data trough
#' the s2.boku.eodc.eu API. Instead symlinks to the internal s2.boku.eodc.eu
#' storage locations can be created or files can be directly copied.
#' @param imageIds vector of image IDs
#' @param conn s2.boku.eodc.eu DBI database connection
#' @param targetDir directory to "download" the data to
#' @param method \code{copy} or \code{symlink}
#' @param basePath base location of the s2.boku.eodc.eu storage
#' @return data frame describing "downloaded" data
#' @export
#' @import dplyr
downloadEodc = function(imageIds, conn, targetDir, method, basePath = '/eodc/private/boku/sentinel2/GRANULES') {
  imageIds = unique(imageIds)
  files = list()
  while (length(imageIds) > 0) {
    tmp = imageIds[1:min(1000, length(imageIds))]
    query = sprintf(
      "SELECT granule_id, utm_id, date::date, band_id, filename FROM s2_images JOIN s2_granules USING (granule_id) WHERE image_id IN (%s)",
      paste0('$', seq_along(tmp), collapse = ', ')
    )
    files[[length(files) + 1]] = dplyr::as_tibble(DBI::dbGetQuery(conn, query, tmp))
    imageIds = imageIds[-seq_along(tmp)]
  }
  files = dplyr::bind_rows(files)

  files = files %>%
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
    ) %>%
    dplyr::mutate(
      symlink = dplyr::if_else(method == 'symlink' & .data$targetExists, Sys.readlink(.data$tileFile), ''),
      srcSize = dplyr::if_else(method == 'copy' & .data$srcExists, file.size(.data$filename), NA_real_),
      targetSize = dplyr::if_else(method == 'copy' & .data$targetExists, file.size(.data$tileFile), NA_real_)
    ) %>%
    dplyr::mutate(
      skip = dplyr::coalesce(.data$targetExists & (method == 'symlink' & .data$symlink == .data$filename | method == 'copy' & .data$srcSize == .data$targetSize), FALSE)
    )

  createDirs(files$tileFile)
  warning(paste(
    'removing', sum(files$targetExists & !files$skip, na.rm = TRUE), 'files,',
    'skipping', sum(files$skip), 'files,',
    'processing', sum(files$srcExists & !files$skip, na.rm = TRUE), 'files')
  )
  unlink(files$tileFile[files$targetExists & !files$skip])

  processed = files %>%
    dplyr::filter(.data$srcExists & !.data$skip) %>%
    dplyr::mutate(success = FALSE)
  if (nrow(processed) > 0) {
    if (method == 'copy') {
      processed = processed %>%
        dplyr::mutate(
          success = purrr::map2_lgl(.data$filename, .data$tileFile, function(x, y){file.copy(x, y, overwrite = TRUE)})
        )
    } else {
      processed = processed %>%
        dplyr::mutate(
          success = file.symlink(.data$filename, .data$tileFile)
        )
    }
  }

  files = files %>%
    dplyr::left_join(processed)
  return(files)
}
