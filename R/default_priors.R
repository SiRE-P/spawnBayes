#' Default prior specification
#'
#' Create a default prior specification for spawnBayes.
#'
#' Default priors are partially informed by the survey design.
#' When `arrival_peak` is not supplied, the prior mean is estimated
#' from the survey-date quantile specified by `arrival_quantile`.
#'
#' The default arrival-spread prior is derived from the median
#' annual survey span (difference between the first and last survey
#' dates within years). The prior mean is approximated as one-sixth
#' of the median survey span, reflecting the assumption that survey
#' windows encompass arrival, residence, departure, and additional
#' buffer periods before and after the run.
#'
#' @param data A data frame containing survey observations.
#' @param abundance Expected spawner abundance. May be a
#'   single value applied to all reaches or a named vector
#'   containing separate values for each reach. If NULL,
#'   reach-specific values are estimated from the observed
#'   survey counts.
#'
#' @param arrival_peak Expected peak arrival date. If NULL,
#'   a default value is estimated using the survey-date
#'   quantile specified by `arrival_quantile`.
#' @param arrival_quantile Quantile of survey dates used to estimate
#'   a default arrival peak date when `arrival_peak` is NULL.
#'   Ignored when `arrival_peak` is supplied.
#' @param assumed_residence Assumed mean residence time (days).
#'   If supplied, this value is used to define the residence-time prior.
#'   If NULL, a default prior is used.
#'
#' @return A list containing prior specifications.
#'
#' @importFrom stats median sd quantile
#'
#' @export
#' 
default_priors <- function(data, abundance = NULL, assumed_residence = NULL, arrival_peak = NULL, arrival_quantile = 0.4) {
  
  arrival_dates <- data |>
    dplyr::mutate(year = lubridate::year(date), yday = lubridate::yday(date)) |>
    dplyr::group_by(year) |>
    dplyr::summarise(arrival_yday = stats::quantile(yday, probs = arrival_quantile), .groups = "drop")
  
  annual_peaks <- data |>
    dplyr::mutate(year = lubridate::year(date)) |>
    dplyr::group_by(reach, year) |>
    dplyr::summarise(
      peak_count = max(spawner_counts, na.rm = TRUE),
      .groups = "drop"
    )
  
  survey_spans <- data |>
    dplyr::mutate(
      year = lubridate::year(date),
      yday = lubridate::yday(date)
    ) |>
    dplyr::group_by(year) |>
    dplyr::summarise(
      survey_span = max(yday) - min(yday),
      .groups = "drop"
    )
  
  spread_guess <- max(median(survey_spans$survey_span, na.rm = TRUE) / 6, 2)
  
  abundance_priors <- annual_peaks |>
    dplyr::group_by(reach) |>
    dplyr::summarise(
      mean =  stats::median(peak_count * 1.5, na.rm = TRUE),
      sdlog =  max(stats::sd(log(pmax(peak_count * 1.5, 1)), na.rm = TRUE ), 0.5),
      .groups = "drop"
    )
  
  if (!is.null(abundance)) {
    
    if (!is.null(names(abundance))) {
      
      missing_reaches <- setdiff(
        abundance_priors$reach,
        names(abundance)
      )
      
      if (length(missing_reaches) > 0)
        stop(
          paste0(
            "Missing abundance values for reach(es): ",
            paste(missing_reaches, collapse = ", ")
          ),
          call. = FALSE
        )
      
      abundance_priors$mean <-
        abundance[
          match(
            abundance_priors$reach,
            names(abundance)
          )
        ]
      
    } else if (length(abundance) == 1) {
      
      abundance_priors$mean <- abundance
      
    } else {
      
      if (length(abundance) != nrow(abundance_priors))
        stop(
          "abundance must be length 1 or match the number of reaches.",
          call. = FALSE
        )
      
      abundance_priors$mean <- abundance
      
    }
    
  }
  
  
  
  if (is.null(arrival_peak))
    arrival_peak <- median(arrival_dates$arrival_yday, na.rm = TRUE)
  
  arrival_peak_sd <- max(sd(arrival_dates$arrival_yday, na.rm = TRUE), 5)

  exit_lag_prior_mean <- if (is.null(assumed_residence)) {
    log(11 - 1)
  } else {
    log(assumed_residence - 1)
  }

  
  list(
    abundance = list(
      reach = abundance_priors$reach,
      mean = abundance_priors$mean,
      sdlog = abundance_priors$sdlog
    ),
    arrival_peak = list(mean = arrival_peak, sd = arrival_peak_sd),
    arrival_sigma = list(mean = 2, sd = 0.3),
    spread = list(mean = log(spread_guess - 1), sd = 0.2),
    spread_sigma = list(mean = 0.5, sd = 0.25),
    exit_lag = list( mean = exit_lag_prior_mean, sd = 0.2),
    count_dispersion = list(mean = log(20), sd = 0.5)
  )
  
}