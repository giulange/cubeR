#' Aggregates data into months
#' @details
#' The aggregation is performed by taking value for a given pixel corresponding
#' to a date when this pixel had highest NDVI value. To do so an additional band
#' called \code{WHICH} is computed storing the corresponding date index for
#' every pixel.
#' @param tiles a data frame describing tiles to be composited (must contain
#'   columns \code{date, tile, band, period, tileFile, whichFile})
#' @param targetDir a directory where computed aggregates should be stored
#' @param tmpDir a directory for temporary files
#' @param skipExisting should already existing images be skipped?
#' @return data frame describing computed aggregated images
#' @import dplyr
#' @export
prepareComposites = function(tiles, targetDir, tmpDir, skipExisting = TRUE) {
  tiles = tiles %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      aggFile = getTilePath(targetDir, .data$tile, .data$period, .data$band)
    )

  skipped = agg = dplyr::tibble(period = character(), tile = character(), band = character(), tileFile = character())
  if (skipExisting) {
    tmp = file.exists(tiles$aggFile)
    skipped = tiles %>%
      dplyr::filter(tmp) %>%
      dplyr::select(.data$period, .data$tile, .data$band, .data$aggFile) %>%
      dplyr::rename(tileFile = .data$aggFile) %>%
      dplyr::distinct()
    tiles = tiles %>%
      dplyr::filter(!tmp)
  }

  if (nrow(tiles) > 0) {
    # skip nodata values because gdal_calc makes pixel a nodata one if it's nodata in any of input bands
    # as we are searching for maximum it will work fine on the gdal_calc step until the nodata value is lower then any valid value
    nodata = tiles %>%
      dplyr::ungroup() %>%
      dplyr::mutate(
        nodataFile = preprocessNodata(.data$tileFile, tmpDir)
      )
    on.exit({
      unlink(nodata$nodataFile)
    })

    agg = nodata %>%
      dplyr::group_by(.data$period, .data$tile, .data$band, .data$whichFile) %>%
      dplyr::arrange(.data$period, .data$tile, .data$band, .data$whichFile, .data$date) %>%
      dplyr::mutate(
        calc = paste0(LETTERS[dplyr::row_number()], ' * (Z == ', dplyr::row_number(), ')'),
        arg = paste0('-', LETTERS[dplyr::row_number()], ' "', .data$nodataFile, '"')
      ) %>%
      dplyr::summarize(
        command = sprintf(
          'gdal_calc.py --quiet -Z {WHICHFILE} %s --calc "%s" --outfile {AGGFILE} --co "COMPRESS=DEFLATE"',
          paste0(.data$arg, collapse = ' '), paste0(.data$calc, collapse = ' + ')
        ),
        aggFile = getTilePath(targetDir, .data$tile[1], .data$period[1], .data$band[1])
      ) %>%
      dplyr::mutate(
        aggFileTmp = paste0(tmpDir, '/', basename(.data$aggFile))
      ) %>%
      dplyr::mutate(
        command = paste(sub('[{]WHICHFILE[}]', .data$whichFile, sub('[{]AGGFILE[}]', .data$aggFileTmp, .data$command)), '&& mv', .data$aggFileTmp, .data$aggFile)
      )
    agg = agg %>%
      dplyr::group_by(.data$period, .data$tile, .data$band) %>%
      dplyr::do({
        ret = system(.data$command, ignore.stdout = TRUE)
        if (ret != 0) {
          cat(.data$command, '\n')
        }
        data.frame(tileFile = .data$aggFile, stringsAsFactors = FALSE)
      })
  }

  return(dplyr::bind_rows(agg, skipped))
}
