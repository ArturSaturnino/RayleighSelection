#' Generates the nerve complex of an open cover.
#'
#' Takes the open cover of a finite set and returns its nerve
#' complex. The output is a simplicial complex that can be used by other functions in the
#' \code{RayleighSelection} package.
#'
#' @param open_cover a list of open sets with \code{open_cover[[i]]} a vector of indices of points
#' corresponding to the \code{i}-th open set in the open cover.
#' @param weight specificies whether to weight 1-simplicies by Jaccard distance
#' @return An object of the class \code{simplicial}. The class \code{simplicial} inherits from
#' the class \code{igraph}.
#' @examples
#' library(RayleighSelection)
#' # Load pre-processed LFW dataset (aligned, cropped, and normalized)
#' data("lfw")
#'
#' # Compute reduced representation using Laplacian eigenmap of pixels with high variance
#' library(dimRed)
#' leim <- LaplacianEigenmaps()
#' lfw_top <- lfw[apply(lfw, 1, var) > 0.9,]
#' emb <- leim@fun(as(t(lfw_top), "dimRedData"), leim@stdpars)
#'
#' # Compute Mapper representation using the Laplacian eigenmap as an auxiliary function and correlation
#' # distance as metric
#' library(TDAmapper)
#' lfw_distances <- (1.0 - cor(lfw_top))
#' m2 <- mapper2D(distance_matrix = lfw_distances,
#'                filter_values = list(emb@data@data[,1], emb@data@data[,2]),
#'                num_intervals = c(40,40),
#'                percent_overlap = 30,
#'                num_bins_when_clustering = 10);
#'
#' # Compute the nerve complex
#' gg <- nerve_complex(m2$points_in_vertex)
#'
#' # Plot the skeleton of the nerve complex colored by the intensity of the 1063rd pixel
#' plot_skeleton(gg, k=as.numeric(lfw[1063,]), spring.constant = 3.0, seed = 3)
#'
#' @export
#'
nerve_complex <- function(open_cover, weight = TRUE) {
  # Builds adjacency matrix and igraph object
  adjacency <- Matrix(adjacencyCpp(open_cover, weight), sparse = TRUE)

  diag(adjacency)<-1

  if (!weight)
  {
      weight <- 'NULL'
  }

  g2 <- graph.adjacency(adjacency, mode="undirected", weighted=weight)

  # Prunes vertices that only one element and simplifies the graph
  kal <- which(lapply(open_cover, length) %in% 1)
  open_cover[kal] <- NULL
  g2 <- delete_vertices(g2, kal)
  g2 <- contract(g2, match(open_cover, unique(open_cover)))
  g2 <- simplify(g2)
  open_cover <- unique(open_cover)

  # Decorates the graph to include node sizes, color, etc.
  V(g2)$size <- log2(as.numeric(lapply(open_cover, length))+1)*2.0
  V(g2)$label <- ""
  V(g2)$frame.color <- "black"

  # Enriches the class with information about the open cover and adjacency matrix
  g2$points_in_vertex <- open_cover
  g2$adjacency <- get.adjacency(g2, sparse = TRUE)
  class(g2) <- c('simplicial', 'igraph')
  return(g2)
}