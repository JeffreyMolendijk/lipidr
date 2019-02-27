#' Collapse transitions 
#' 
#' Calculate a single intensity for molecules with multiple transitions
#'
#' @param data Skyline data.frame created by \code{\link{read.skyline}}
#' @param method choose to summarize multiple transitions by taking average or max intensity
#'
#' @importFrom dplyr %>% vars matches arrange group_by_at ungroup group_indices summarise first
#' @return
#' @export
#'
#' @examples
summarize_transitions <- function(data, method=c("max", "average")) {
  stopifnot(inherits(data, "SkylineExperiment"))
  if(data@attrs$summarized){
    stop("data is already summarized")
  }
  
  method = match.arg(method)
  multi_transitions = to_df(data) %>% group_by_at(vars(-1,-matches("^Product")))
  transition_gps = split(multi_transitions$TransitionId, multi_transitions %>% group_indices())
  sum_fun = ifelse(method == "average", mean, max)
  
  assay_list = lapply(assays(data), function(m) {
    mret = plyr::laply(transition_gps, function(x) { 
      if(length(x) == 1) {
        return(m[x,])
      } else {
        return(apply(m[x,], 2, sum_fun, na.rm=TRUE))
      }
    })
    rownames(mret) <- names(transition_gps)
    return (mret)
  })
  
  assay_list = as(assay_list, "SimpleList")
  mcols(assay_list) <- mcols(assays(data))
  
  row_data = multi_transitions %>% cbind(group_idx=group_indices(.)) %>% 
    summarise(rowname=first(group_idx)) %>%
    toDataFrame()
  
  row_data = row_data[ row.names(assay_list[[1]]), ]
  
  attrs = data@attrs
  attrs$summarized = TRUE
  attrs$dimnames[[1]] = "MoleculeId"
  SkylineExperiment(assay_list=assay_list, attrs=attrs, colData=colData(data), rowData=row_data)
}

