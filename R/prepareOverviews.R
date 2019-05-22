#' Creates overviews
#' @param input a data frame describing images to be merged into overviews (must
#'   contain \code{period, band, tile, tileFile}
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param tmpDir a directory for temporary files
#' @param resolution overview resolution
#' @param method resampling method (near, bilinear, cubic, cubicspline, lanczos,
#'   average, mode, max, min, med, q1, q3 - see gdalwarp doc)
#' @param skipExisting should already existing tiles be skipped?
#' @param gdalOpts additional gdalwarp options, e.g. enabling multithreading
#' @return data frame describing created tiles
#' @import dplyr
#' @export
prepareOverviews = function(input, targetDir, tmpDir, resolution, method, skipExisting, gdalOpts) {
  input = input %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      outFile = getTilePath(targetDir, .data$tile, .data$period, .data$band)
    )

  skipped = processed = dplyr::tibble(period = character(), tile = character(), band = character(), tileFile = character())
  if (skipExisting) {
    tmp = file.exists(input$outFile)
    skipped = input %>%
      dplyr::filter(tmp) %>%
      dplyr::select(.data$period, .data$tile, .data$band, .data$outFile) %>%
      dplyr::rename(tileFile = .data$outFile) %>%
      dplyr::distinct()
    input = input %>%
      dplyr::filter(!tmp)
  }

  if (nrow(input) > 0) {
    createDirs(input$outFile)
    unlink(input$outFile)

    processed = input %>%
      dplyr::group_by(.data$period, .data$band, .data$tile) %>%
      dplyr::summarize(
        inFiles = paste0(shQuote(.data$tileFile), collapse = ' '),
        outFile = dplyr::first(.data$outFile),
        tmpFile = paste0(tmpDir, '/', basename(dplyr::first(.data$outFile)))
      ) %>%
      dplyr::mutate(
        command = sprintf(
          'gdalwarp -q -overwrite %s -r %s -tr %d %d %s %s && mv %s %s',
          gdalOpts, method, resolution, resolution, .data$inFiles, shQuote(.data$tmpFile), shQuote(.data$tmpFile), shQuote(.data$outFile)
        )
      )
    tmpFiles = processed$tmpFile
    on.exit({
      unlink(tmpFiles)
    })

    processed = processed %>%
      dplyr::group_by(.data$period, .data$band, .data$tile) %>%
      dplyr::do({
        system(.data$command, ignore.stdout = TRUE)
        dplyr::as.tbl(data.frame(tileFile = .data$outFile, processed = TRUE, stringsAsFactors = FALSE))
      }) %>%
      dplyr::ungroup()
  }

  return(dplyr::bind_rows(processed, skipped))
}
