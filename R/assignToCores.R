#' Split data into chunks for parallel processing.
#' @description Splits data into (no more than) \code{nCores * nTimes} chunks
#' while preserving the grouping already applied to the \code{data}.
#' @details Spawning new processes and collecting results introduces an overhead
#'   which is proportional to the number of parallel processing chunks.
#'   Therefore it's suboptimal if the number of chunks is much bigger than the
#'   number of workers (cores) (e.g. processing 10k chunks on 10 cores). On the
#'   other hand if the processing time can vary greatly from chunk to chunk it's
#'   better to have more chunks than workers, so workers which finished earlier
#'   can process remaining chunks.
#' @param data data.frame to be splitted
#' @param nCores number of cores
#' @param nTimes number of chunks per core
#' @return list of processing chunks (each chunk being a data.frame)
#' @export
assignToCores = function(data, nCores, nTimes = 10) {
  if (nrow(data) == 0) {
    return(list(data))
  }
  if (length(dplyr::group_vars(data)) > 0) {
    nGroups = dplyr::n_groups(data)
    groupIds = dplyr::group_indices(data)
  } else {
    nGroups = nrow(data)
    groupIds = 1:nrow(data)
  }
  groupsToChunks = rep(1:(nCores * nTimes), each = ceiling(nGroups / nCores / nTimes))[1:nGroups]
  chunks = split(data, groupsToChunks[groupIds])
  return(chunks)
}
