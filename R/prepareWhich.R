#' Generates a band storing a date within a period with maximum value of a given
#' band.
#' @details The date is encoded per pixel using an order of a (sorted) date
#' within a period, e.g. if a given period for a given tile consists of three
#' dates \code{2019-01-06, 2019-01-01 & 2019-01-11}, then \code{1} corresponds
#' to \code{2019-01-01}, \code{2} to \code{2019-01-06} and \code{3} to
#' {2019-01-11}.
#'
#' Processing is done within groups defined by \code{period & band}
#'
#' Processing is divided into two steps. \enumerate{ \item In the first step a
#' maximum value among all dates in a period is computed. \iten In the second
#' step an output band is computed by comparing values at particular dates to
#' the maximum one. If the maximum value occurs for many dates, the last date is
#' taken. }
#' @param tiles a data frame describing tiled images (must contain at least
#'   columns \code{period, date, tile, band, tileFile})
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param tmpDir a directory for temporary files
#' @param bandName output band name
#' @param skipExisting should already existing images be skipped?
#' @return data frame describing generated images
#' @export
#' @import dplyr
prepareWhich = function(tiles, targetDir, tmpDir, bandName, skipExisting) {
  stopifnot(
    is.vector(bandName), is.character(bandName), length(bandName) == 1, all(!is.na(bandName))
  )

  tiles = tiles %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      whichFile = getTilePath(targetDir, .data$tile, .data$period, bandName)
    )

  skipped = bandWhich = dplyr::tibble(period = character(), tile = character(), tileFile = character())
  if (skipExisting) {
    tmp = file.exists(tiles$whichFile)
    skipped = tiles %>%
      dplyr::filter(tmp) %>%
      dplyr::select(.data$period, .data$tile, .data$whichFile) %>%
      dplyr::rename(tileFile = .data$whichFile) %>%
      dplyr::distinct()
    tiles = tiles %>%
      dplyr::filter(!tmp)
  }

  if (nrow(tiles) > 0) {
    nodata = tiles %>%
      dplyr::mutate(nodataFile = preprocessNodata(.data$tileFile, tmpDir))

    bandMax = nodata %>%
      dplyr::group_by(.data$period, .data$tile, .data$whichFile) %>%
      dplyr::arrange(.data$period, .data$tile, .data$date) %>%
      dplyr::mutate(
        calc1 = LETTERS[dplyr::row_number()],
        calc2 = paste0(dplyr::row_number(), ' * (', LETTERS[dplyr::row_number()], ' == Z)'),
        arg = paste0('-', LETTERS[dplyr::row_number()], ' "', .data$nodataFile, '"'),
      ) %>%
      dplyr::summarize(
        stage1Command = sprintf(
          'gdal_calc.py %s --calc "%s" --outfile {STAGE1FILE} --overwrite --type Int16 --NoDataValue -32768',
          paste0(.data$arg, collapse = ' '),
          sub('maximum[(]A[)]', 'A', paste0(paste0(rep('maximum(', dplyr::n()), collapse = ''), paste0(.data$calc1, collapse = '), '), ')'))
        ),
        stage2Command = sprintf(
          'gdal_calc.py -Z {STAGE1FILE} %s --calc "%s" --outfile {STAGE2FILE} --overwrite --type Byte --NoDataValue 0 --co "COMPRESS=DEFLATE"',
          paste0(.data$arg, collapse = ' '),
          sub('maximum[(]1 [*] [(]A == Z[)][)]', 'A == Z', paste0(paste0(rep('maximum(', dplyr::n()), collapse = ''), paste0(.data$calc2, collapse = '), '), ')'))
        )
      ) %>%
      dplyr::group_by(.data$period, .data$tile) %>%
      dplyr::mutate(
        stage1File = paste0(tmpDir, '/which1_', basename(getTilePath(tmpDir, .data$tile, .data$period, bandName))),
        stage2File = paste0(tmpDir, '/which2_', basename(getTilePath(tmpDir, .data$tile, .data$period, bandName)))
      ) %>%
      dplyr::mutate(
        stage1Command = sub('[{]STAGE1FILE[}]', .data$stage1File, .data$stage1Command),
        stage2Command = sub('[{]STAGE2FILE[}]', .data$stage2File, sub('[{]STAGE1FILE[}]', .data$stage1File, .data$stage2Command))
      )
    on.exit({
      unlink(c(bandMax$stage1File, bandMax$stage2File, nodata$nodataFile))
    })

    bandWhich = bandMax %>%
      dplyr::group_by(.data$period, .data$tile) %>%
      do({
        ret = system(.data$stage1Command, ignore.stdout = TRUE)
        if (ret != 0) {
          cat(.data$stage1Command, '\n')
        }
        ret = system(.data$stage2Command, ignore.stdout = TRUE)
        if (ret != 0) {
          cat(.data$stage2Command, '\n')
        }
        file.rename(.data$stage2File, .data$whichFile)
        data.frame(tileFile = .data$whichFile, stringsAsFactors = FALSE)
      }) %>%
      dplyr::ungroup()
  }

  return(dplyr::bind_rows(bandWhich, skipped))
}