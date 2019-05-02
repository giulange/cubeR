#' Applies a SNAP workflow
#' @param products a data frame describing input products, has to contain
#'   \code{inFile} and \code{outFile} columns
#' @param workflowFile path to an XML file describing the workflow, the
#'   \code{${in}} and \code{${out}} placeholders in the XML file will be
#'   replaced by the input and output file names, respectively
#' @param gptPath path to the SNAP's gpt batch processor
#' @param memoryLimit memory limit for the processing (M/G suffixes can be used)
#' @param threadsLimit maximum number of threads to be used during the
#'   processing
#' @param tileCacheSize maximum size of tile cache (M/G suffixes can be used)
#' @return data frame describing processing output
#' @import dplyr
#' @export
# applySnapWorkflow = function(products, workflowFile, gptPath, memoryLimit = '2G', threadsLimit = 8, tileCacheSize = '1G') {
#   products = products %>%
#     dplyr::mutate(
#       command = sprintf('%s %s -x -J-Xmx%s -q %d -c %s "-Pin=%s" "-Pout=%s"', gptPath, workflowFile, memoryLimit, threadsLimit, tileCacheSize, inFile, outFile)
#     )
#   products = products %>%
#     dplyr::group_by(inFile, outFile) %>%
#     do({
#       system(.$command, ignore.stdout = TRUE)
#       dplyr::tibble(success = TRUE)
#     }) %>%
#     dplyr::ungroup()
#   return(products)
# }
