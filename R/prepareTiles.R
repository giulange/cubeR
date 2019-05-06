#' Generates EQUI7 tiles
#' @param rawTilesMap a data frame describing raw images to tiles mapping
#'   obtained from \code{\link{mapRawTiles}}. \ Must have at least \code{date,
#'   band, utm, file, tile, bbox} columns
#' @param targetDir a directory where tiles should be saved (a separate
#'   subdirectory for each tile will be created)
#' @param gridFile a file providing a tiling grid (in any file format supported
#'   by the \code{\link[sf]{read_sf}}). All features have to have a \code{TILE}
#'   attribute denoting the tile name. The tiles projection will follow the grid
#'   file projection.
#' @param tmpDir a directory for temporary files
#' @param method resampling method (near, bilinear, cubic, cubicspline, lanczos,
#'   average, mode, max, min, med, q1, q3 - see gdalwarp doc)
#' @param skipExisting should already existing tiles be skipped?
#' @param gdalOpts additional gdalwarp options, e.g. enabling multithreading
#' @return data frame describing created tiles
#' @import dplyr
#' @export
prepareTiles = function(rawTilesMap, targetDir, gridFile, tmpDir, method, skipExisting = TRUE, gdalOpts = '') {
  options(scipen = 100)
  if (!dir.exists(tmpDir)) {
    dir.create(tmpDir, recursive = TRUE)
  }
  grid = sf::read_sf(gridFile, quiet = TRUE)
  prj = sf::st_crs(grid)$proj4string

  noData = dplyr::tibble(
    band = c(sprintf('B%02d', 1:12), 'B8A', 'AOT', 'CLD', 'DEM', 'PVI', 'SCL', 'SNW', 'TCI', 'VIS', 'WVP', 'albedo', 'FAPAR', 'FCOVER', 'LAI'),
    nodata = c(rep(0, 22), 65535, rep(32767, 3))
  )

  # generate output file names
  rawTilesMap = rawTilesMap %>%
    dplyr::mutate(
      tileFile = sprintf('%s/%s/%s_%s_%s.tif', targetDir, .data$tile, .data$date, .data$band, .data$tile)
    )

  # create target directory structure
  for (i in unique(dirname(rawTilesMap$tileFile))) {
    dir.create(i, recursive = TRUE, showWarnings = FALSE)
  }

  # skip already existing tiles
  skipped = dplyr::tibble(tileFile = character())
  if (skipExisting) {
    rawTilesMap = rawTilesMap %>%
      dplyr::left_join(
        rawTilesMap %>%
          dplyr::select(.data$tileFile) %>%
          dplyr::distinct() %>%
          dplyr::mutate(exists = file.exists(.data$tileFile))
      )
    skipped = rawTilesMap %>%
      dplyr::ungroup() %>%
      dplyr::filter(.data$exists) %>%
      dplyr::select(.data$date, .data$band, .data$tile, .data$tileFile) %>%
      dplyr::distinct()
    rawTilesMap = rawTilesMap %>%
      dplyr::filter(!.data$exists) %>%
      dplyr::select(-.data$exists)
  }

  # reproject raw files
  imgs = rawTilesMap %>%
    dplyr::select(.data$date, .data$band, .data$utm, .data$file) %>%
    dplyr::distinct() %>%
    dplyr::inner_join(noData) %>%
    dplyr::group_by(.data$date, .data$band, .data$utm, .data$file) %>%
    dplyr::mutate(
      equi7File = path.expand(paste0(tmpDir, '/', basename(.data$file)))
    ) %>%
    dplyr::mutate(
      command = paste('gdalwarp ', gdalOpts, ' -q -overwrite -tr 10.0 10.0 -r ', dplyr::if_else(.data$band %in% 'SCL', 'near', method), ' -srcnodata', .data$nodata, '-t_srs', paste0('"', prj, '"'), paste0('"', path.expand(.data$file), '"'), paste0('"', .data$equi7File, '"'))
    )
  imgs = imgs %>%
    dplyr::group_by(.data$date, .data$band, .data$utm, .data$file, .data$equi7File) %>%
    dplyr::do({
      system(.data$command, ignore.stdout = TRUE)
      dplyr::tibble(success = TRUE)
    }) %>%
    dplyr::ungroup() %>%
    dplyr::select(-.data$file, -.data$success)

  on.exit(unlink(imgs$equi7File))

  # retile
  tiles = rawTilesMap %>%
    dplyr::left_join(imgs) %>%
    dplyr::group_by(.data$date, .data$band, .data$tile, .data$bbox) %>%
    dplyr::summarize(
      inputFiles = paste0('"', .data$equi7File, '"', collapse = ' ')
    ) %>%
    dplyr::mutate(
      tileFile = getTilePath(targetDir, .data$tile, .data$date, .data$band)
    ) %>%
    dplyr::mutate(
      tileFileTmp = paste0(tmpDir, '/', basename(.data$tileFile))
    ) %>%
    dplyr::mutate(command = paste('gdalwarp ', gdalOpts, ' -q -overwrite -co "COMPRESS=DEFLATE" -te', .data$bbox, .data$inputFiles, .data$tileFileTmp, '&& mv', .data$tileFileTmp, .data$tileFile)) %>%
    dplyr::select(-.data$inputFiles, -.data$bbox)

  tiles = tiles %>%
    dplyr::group_by(.data$date, .data$band, .data$tile, .data$tileFile) %>%
    dplyr::do({
      system(.data$command, ignore.stdout = TRUE)
      dplyr::tibble(success = TRUE)
    }) %>%
    dplyr::select(-.data$success) %>%
    dplyr::ungroup()

  return(bind_rows(skipped, tiles))
}
