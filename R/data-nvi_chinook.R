#' Northwest Vancouver Island Chinook spawner survey data
#'
#' Spawner survey observations from Artlish River, Kaouk River, and
#' Tahsish River collected by Fisheries and Oceans Canada's
#' South Coast Stock Assessment.
#'
#' The dataset is used in the spawnBayes vignettes to demonstrate
#' both single-population and multi-population abundance estimation.
#'
#' @format A data frame containing spawner survey observations with the
#' following variables:
#' \describe{
#'   \item{date}{Survey date.}
#'   \item{stream}{Survey stream identifier. Identical to group in this dataset.}
#'   \item{group}{Population or river name.}
#'   \item{spawner_counts}{Observed salmon count.}
#'   \item{observer_efficiency}{Estimated observer efficiency.}
#'   \item{survey_error_group}{Survey type or survey quality grouping variable.}
#' }
#'
#' @source Fisheries and Oceans Canada NuSEDS database.
#'
#' @examples
#' data(nvi_chinook)
#' head(nvi_chinook)
#'
#' @docType data
#' @keywords datasets
#' @name nvi_chinook
NULL