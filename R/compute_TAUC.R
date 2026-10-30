#' Compute traditional TAUC abundance estimates
#'
#' Calculate reach-specific annual abundance estimates using the
#' traditional trapezoidal area-under-the-curve (TAUC) method and
#' an assumed mean residence time (survey life).
#'
#' The calculation follows the historical TAUC implementation
#' used in salmon escapement assessments, including half-life
#' adjustments before the first survey and after the final survey.
#'
#' @param data A data frame containing survey observations.
#' @param assumed_residence Assumed mean residence time (days).
#'
#' @return A data frame containing reach-specific annual TAUC
#' abundance estimates.
#'
#' @keywords internal
compute_TAUC <- function(data, assumed_residence) {
  
  if (is.null(assumed_residence))
    return(NULL)
  
  data |>
    dplyr::mutate(
      year = lubridate::year(date)
    ) |>
    dplyr::group_by(reach, year) |>
    dplyr::arrange(date, .by_group = TRUE) |>
    dplyr::mutate(
      tdiff = as.numeric(date - dplyr::lag(date)),
      xbar = (spawner_counts + dplyr::lag(spawner_counts)) / 2,
      fishdays = dplyr::case_when(
        is.na(xbar) ~ spawner_counts * assumed_residence / 2,
        TRUE ~ tdiff * xbar
      ),
      cumulative = cumsum(fishdays)
    ) |>
    dplyr::summarise(
      TAUC = round(
        (
          max(cumulative, na.rm = TRUE) +
            spawner_counts[which.max(date)] *
            (assumed_residence / 2)
        ) / assumed_residence
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(reach, year)
}