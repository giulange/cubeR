#' Aggregates data into periods
#' @param input a data frame describing tiles to be aggregated (must contain
#'   columns \code{date, tile, band, period, tileFile})
#' @param targetDir a directory where computed aggregates should be stored
#' @param tmpDir a directory for temporary files
#' @param pythonDir a directory containing the \code{which.py} python script
#'   used to compute the output
#' @param outputBandTmpl result band name template (%s will be subsituted with
#'   the current band name)
#' @param skipExisting should already existing images be skipped?
#' @param blockSize processing block size used during computations - larger
#'   block requires more memory but (generally) makes computations faster
#' @return data frame describing computed aggregated images
#' @import dplyr
#' @export
prepareCounts = function(input, targetDir, tmpDir, pythonDir, outputBandTmpl = '%scount', skipExisting = TRUE, blockSize = 512) {
  processed = input %>%
    dplyr::ungroup() %>%
    tidyr::nest(input = one_of('tileFile', 'date')) %>%
    dplyr::mutate(
      outBand = sprintf(outputBandTmpl, .data$band)
    ) %>%
    dplyr::mutate(
      outFile = getTilePath(targetDir, .data$tile, .data$period, .data$outBand)
    ) %>%
    dplyr::mutate(
      tmpFile = paste0(tmpDir, '/', basename(.data$outFile))
    )

  skipped = dplyr::tibble(period = character(), tile = character(), outBand = character(), outFile = character())
  if (skipExisting) {
    tmp = file.exists(processed$outFile)
    skipped = processed %>%
      dplyr::filter(tmp) %>%
      dplyr::select(.data$period, .data$tile, .data$outBand, .data$outFile)
    processed = processed %>%
      dplyr::filter(!tmp) %>%
      dplyr::mutate(processed = NA)
  }

  if (nrow(processed) > 0) {
    createDirs(processed$outFile)
    unlink(processed$outFile)

    processed = processed %>%
      dplyr::group_by(.data$period, .data$tile, .data$band) %>%
      dplyr::mutate(
        inFilesFile = sub('[^.]+$', 'input', .data$tmpFile)
      ) %>%
      dplyr::mutate(
        command = sprintf(
          'python3 %s/sum.py --blockSize %d --binary --includeZero %s %s && mv %s %s',
          pythonDir, blockSize, .data$tmpFile, .data$inFilesFile, .data$tmpFile, .data$outFile
        )
      )
    tmpFiles = c(processed$tmpFile, processed$inFilesFile)
    on.exit({
      unlink(tmpFiles)
    })

    processed = processed %>%
      dplyr::group_by(.data$period, .data$tile, .data$outBand, .data$outFile) %>%
      dplyr::do({
        writeLines(.data$input[[1]]$tileFile, .data$inFilesFile)
        system(.data$command, ignore.stdout = TRUE)
        data.frame(processed = TRUE)
      }) %>%
      dplyr::ungroup()
  }

  processed = processed %>%
    dplyr::select(.data$period, .data$tile, .data$outBand, .data$outFile, .data$processed)
  return(bind_rows(processed, skipped) %>% dplyr::rename(band = .data$outBand, tileFile = .data$outFile))
}
