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
#' @return data frame describing created tiles
#' @import dplyr
#' @export
prepareTiles = function(rawTilesMap, targetDir, gridFile, tmpDir, method = 'bilinear', skipExisting = TRUE) {
  options(scipen = 100)
  if (!dir.exists(tmpDir)) {
    dir.create(tmpDir, recursive = TRUE)
  }
  grid = sf::read_sf(gridFile)
  prj = sf::st_crs(sf::st_read(gridFile))$proj4string

  noData = dplyr::tibble(
    band = c(sprintf('B%02d', 1:12), 'B8A', 'AOT', 'CLD', 'DEM', 'PVI', 'SCL', 'SNW', 'TCI', 'VIS', 'WVP', 'albedo', 'FAPAR', 'FCOVER', 'LAI'),
    nodata = c(rep(0, 22), 65535, rep(32767, 3))
  )

  # generate output file names
  rawTilesMap = rawTilesMap %>%
    dplyr::mutate(
      tileFile = sprintf('%s/%s/%s_%s_%s.tif', targetDir, tile, date, band, tile)
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
          dplyr::select(tileFile) %>%
          dplyr::distinct() %>%
          dplyr::mutate(exists = file.exists(tileFile))
      )
    skipped = rawTilesMap %>%
      dplyr::ungroup() %>%
      dplyr::filter(exists) %>%
      dplyr::select(date, band, tile, tileFile) %>%
      dplyr::distinct()
    rawTilesMap = rawTilesMap %>%
      dplyr::filter(!exists) %>%
      dplyr::select(-exists)
  }

  # reproject raw files
  imgs = rawTilesMap %>%
    dplyr::select(date, band, utm, file) %>%
    dplyr::distinct() %>%
    dplyr::inner_join(noData) %>%
    dplyr::group_by(date, band, utm, file) %>%
    dplyr::mutate(
      equi7File = path.expand(paste0(tmpDir, '/', basename(file)))
    ) %>%
    dplyr::mutate(
      command = paste('gdalwarp -overwrite -tr 10.0 10.0 -r ', dplyr::if_else(band %in% 'SCL', 'near', method), ' -srcnodata', nodata, '-t_srs', paste0('"', prj, '"'), paste0('"', path.expand(file), '"'), paste0('"', equi7File, '"'))
    )
  imgs = imgs %>%
    dplyr::group_by(date, band, utm, file, equi7File) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::tibble(success = TRUE)
    }) %>%
    dplyr::ungroup() %>%
    dplyr::select(-file, -success)

  on.exit(unlink(imgs$equi7File))

  # retile
  tiles = rawTilesMap %>%
    dplyr::left_join(imgs) %>%
    dplyr::group_by(date, band, tile, bbox) %>%
    dplyr::summarize(
      inputFiles = paste0('"', equi7File, '"', collapse = ' ')
    ) %>%
    dplyr::mutate(
      tileFile = getTilePath(targetDir, tile, date, band)
    ) %>%
    dplyr::mutate(
      tileFileTmp = paste0(tmpDir, '/', basename(tileFile))
    ) %>%
    dplyr::mutate(command = paste('gdalwarp -overwrite -co "COMPRESS=DEFLATE" -te', bbox, inputFiles, tileFileTmp, '&& mv', tileFileTmp, tileFile)) %>%
    dplyr::select(-inputFiles, -bbox)

  tiles = tiles %>%
    dplyr::group_by(date, band, tile, tileFile) %>%
    dplyr::do({
      system(.$command, ignore.stdout = TRUE)
      dplyr::tibble(success = TRUE)
    }) %>%
    dplyr::select(-success)

  return(bind_rows(skipped, tiles))
}
