#' Create a spawnBayes data template
#'
#' Create a csv template illustrating the expected
#' input data structure for spawnBayes.
#'
#' The template includes commonly used columns for
#' survey date, group identity (e.g., reach, stream, population), observed spawner counts,
#' observer efficiency, survey coverage, and survey-error
#' classification.
#'
#' @param file Output file name.
#'
#' @return The path to the created file.
#'
#' @details
#' The template contains a minimal working example suitable
#' for fitting a spawnBayes model.
#'
#' The \code{group} column identifies the unit for which
#' abundance is estimated and timing is allowed to vary.
#' Groups may represent reaches, streams, rivers,
#' populations, index areas, or other biologically
#' meaningful survey units.
#'
#' Observer efficiency and coverage should be supplied as
#' proportions ranging from 0 to 1.
#'
#' @export
template_file <- function(
    file = "spawnBayes_template.csv"
) {
  
  template <- data.frame(
    date = c(
      "2024-09-01",
      "2024-09-10",
      "2024-09-20"
    ),
    group = "Group 1",
    spawner_counts = c(
      150,
      320,
      180
    ),
    observer_efficiency = 1,
    coverage = 1,
    survey_error_group = "default"
  )
  
  utils::write.csv(
    template,
    file,
    row.names = FALSE
  )
  
  invisible(
    normalizePath(file)
  )
  
}
  