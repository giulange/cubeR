#' Aggregates data into periods
#' @param input a data frame describing tiles to be aggregated (must contain
#'   columns \code{date, tile, band, period, tileFile})
#' @param targetDir a directory where computed aggregates should be stored
#' @param tmpDir a directory for temporary files
#' @param pythonDir a directory containing the \code{which.py} python script
#'   used to compute the output
#' @param quantiles vector of quantiles to be computed
#' @param skipExisting should already existing images be skipped?
#' @param blockSize processing block size used during computations - larger
#'   block requires more memory but (generally) makes computations faster
#' @return data frame describing computed aggregated images
#' @import dplyr
#' @export
prepareQuantiles = function(input, targetDir, tmpDir, pythonDir, quantiles, skipExisting = TRUE, blockSize = 512) {
  input = input %>%
    dplyr::ungroup() %>%
    tidyr::nest(input = tidyr::one_of('tileFile', 'date'))
  output = input %>%
    dplyr::select(.data$period, .data$tile, .data$band) %>%
    dplyr::mutate(x = 1L) %>%
    dplyr::inner_join(dplyr::tibble(x = 1L, outBand = sprintf('q%02d', round(quantiles * 100)))) %>%
    dplyr::select(-.data$x) %>%
    dplyr::mutate(
      outBand = paste0(.data$band, .data$outBand)
    ) %>%
    dplyr::mutate(
      outFile = getTilePath(targetDir, .data$tile, .data$period, .data$outBand)
    ) %>%
    dplyr::group_by(.data$period, .data$tile, .data$band) %>%
    dplyr::mutate(
      tmpFile = paste0(tmpDir, '/', basename(.data$outFile)),
      nMissing = n() - sum(file.exists(.data$outFile))
    ) %>%
    dplyr::group_by(.data$period, .data$tile, .data$band, .data$nMissing) %>%
    tidyr::nest(output = tidyr::one_of('outBand', 'tmpFile', 'outFile')) %>%
    dplyr::ungroup()
  input = input %>%
    dplyr::inner_join(output)

  skipped = processed = dplyr::tibble(period = character(), tile = character(), outBand = character(), outFile = character())
  if (skipExisting) {
    skipped = input %>%
      dplyr::filter(.data$nMissing == 0) %>%
      dplyr::select(.data$period, .data$tile, .data$output) %>%
      tidyr::unnest()
    input = input %>%
      dplyr::filter(.data$nMissing > 0)
  }

  if (nrow(input) > 0) {
    outFiles = dplyr::bind_rows(input$output)$outFile
    createDirs(outFiles)
    unlink(outFiles)

    processed = input %>%
      dplyr::group_by(.data$period, .data$tile, .data$band) %>%
      dplyr::mutate(
        outFileTmpl = sub(paste0(.data$band, 'q[0-9][0-9]'), paste0(.data$band, 'q%02d'), first(.data$output[[1]]$tmpFile))
      ) %>%
      dplyr::mutate(
        inFilesFile = sub('[^.]+$', 'input', .data$outFileTmpl)
      ) %>%
      dplyr::mutate(
        command = sprintf(
           'python3 %s/quantiles.py --blockSize %d --mode precise %s %s --q %s',
           pythonDir, blockSize, .data$outFileTmpl, .data$inFilesFile, paste0(quantiles, collapse = ' ')
        )
      )
    tmpFiles = c(dplyr::bind_rows(processed$output)$tmpFile, processed$inFilesFile)
    on.exit({
      unlink(tmpFiles)
    })

    processed = processed %>%
      dplyr::do({
        writeLines(.data$input[[1]]$tileFile, .data$inFilesFile)
        ret = system(.data$command, ignore.stdout = TRUE)
        if (ret == 0) {
          file.rename(.data$output[[1]]$tmpFile, .data$output[[1]]$outFile)
        }
        .data$output[[1]] %>% dplyr::mutate(processed = TRUE)
      }) %>%
      dplyr::ungroup() %>%
      dplyr::select(.data$period, .data$tile, .data$outBand, .data$outFile, .data$processed)
  }

  return(dplyr::bind_rows(processed, skipped) %>% dplyr::rename(band = .data$outBand, tileFile = .data$outFile))
}
