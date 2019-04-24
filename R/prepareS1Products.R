#'
#' @import dplyr
#' @export
prepareS1Products = function(products, tmpDir, targetDir, workflowFile, gptPath, memoryLimit = '4G', threadsLimit = 8, tileCacheSize = '1G') {
  products = products %>%
    dplyr::rename(inFile = file) %>%
    dplyr::mutate(outFile = paste0(tmpDir, '/', sub('zip$', 'dim', basename(inFile))))
  tmp = applySnapWorkflow(products, workflowFile, gptPath, memoryLimit, threadsLimit, tileCacheSize)
  products = products %>%
    dplyr::inner_join(tmp) %>%
    dplyr::group_by(date, asc) %>%
    dplyr::mutate(
      s1File = sprintf('%s/%s_%s_%02d.tif', targetDir, date, ifelse(asc, 'asc', 'desc'), row_number())
    ) %>%
    dplyr::mutate(
      command = sprintf('gdalwarp -overwrite -srcnodata 0 -co "COMPRESS=DEFLATE" %s %s', sub('dim$', 'data/Sigma0_VV.img', outFile), s1File)
    )
  products %>%
    dplyr::group_by(s1File) %>%
    do({
      system(.$command, ignore.stdout = TRUE)
      tibble(success = TRUE)
    })

  return(products %>% dplyr::select(-success, -inFile))
}