#' Construct Stan data for spawnBayes
#'
#' Convert validated survey data and prior specifications into
#' the data list required by the spawnBayes Stan model.
#'
#' @param data A validated data frame containing survey observations.
#' @param priors A prior specification object returned by
#'   [default_priors()].
#' @param outlier_model Logical. If TRUE, include the outlier
#'   observation model in the Stan data passed to spawnBayes.
#'
#' @return A list containing:
#' \describe{
#'   \item{stan_data}{Data list supplied to Stan.}
#'   \item{day_stand}{Reference day used for day standardization.}
#'   \item{year_lookup}{Mapping between Stan year indices and calendar years.}
#'   \item{reach_lookup}{Mapping between Stan reach indices and reach names.}
#' }
#'
#' @keywords internal
make_stan_data <- function(data, priors, outlier_model = TRUE) {
  
  dat <- data |>
    dplyr::mutate(
      year = lubridate::year(date),
      yday = lubridate::yday(date)
    ) |>
    dplyr::arrange(date)
  
  day_stand <- min(dat$yday)
  
  dat <- dat |>
    dplyr::mutate(
      year_ind = as.integer(factor(year)),
      reach_ind = as.integer(factor(reach)),
      day = yday - day_stand
    )
  
  year_lookup <- dat |>
    dplyr::distinct(year_ind, year) |>
    dplyr::arrange(year_ind)
  
  reach_lookup <- dat |>
    dplyr::distinct(reach_ind, reach) |>
    dplyr::arrange(reach_ind)
  
  abundance_prior_mean <-
    priors$abundance$mean[
      match(
        reach_lookup$reach,
        priors$abundance$reach
      )
    ]
  
  abundance_prior_sdlog <-
    priors$abundance$sdlog[
      match(
        reach_lookup$reach,
        priors$abundance$reach
      )
    ]
  
  if (any(is.na(abundance_prior_mean)))
    stop(
      "Failed to match abundance prior means to reaches.",
      call. = FALSE
    )
  
  if (any(is.na(abundance_prior_sdlog)))
    stop(
      "Failed to match abundance prior standard deviations to reaches.",
      call. = FALSE
    )
  
  stan_data <- list(
    
    # dimensions
    n_years = nrow(year_lookup),
    n_reaches = nrow(reach_lookup),
    n_obs = nrow(dat),
    
    # observations
    year = dat$year_ind,
    reach = dat$reach_ind,
    day = dat$day,
    live_counts = as.integer(round(dat$spawner_counts)),
    
    # survey error groups
    n_survey_error_groups =
      nlevels(dat$survey_error_group),
    
    survey_error_group_id =
      as.integer(dat$survey_error_group),
    
    # model options
    outlier_model =
      as.integer(outlier_model),
    
    # abundance priors
    abundance_prior_mean =
      abundance_prior_mean,
    
    abundance_prior_sdlog =
      abundance_prior_sdlog,
    
    # arrival timing prior
    arrival_prior_mean =
      priors$arrival_peak$mean - day_stand,
    
    arrival_prior_sd =
      priors$arrival_peak$sd,
    
    # timing spread prior
    spread_prior_mean =
      priors$spread$mean,
    
    spread_prior_sd =
      priors$spread$sd,
    
    # exit lag prior
    exit_lag_prior_mean =
      priors$exit_lag$mean,
    
    exit_lag_prior_sd =
      priors$exit_lag$sd,
    
    # arrival-date variability prior
    arrival_sigma_prior_mean =
      priors$arrival_sigma$mean,
    
    arrival_sigma_prior_sd =
      priors$arrival_sigma$sd,
    
    # arrival-spread variability prior
    arrival_spread_sigma_prior_mean =
      priors$spread_sigma$mean,
    
    arrival_spread_sigma_prior_sd =
      priors$spread_sigma$sd,
    
    # exit-lag variability prior
    exit_lag_sigma_prior_mean =
      priors$spread_sigma$mean,
    
    exit_lag_sigma_prior_sd =
      priors$spread_sigma$sd,
    
    # exit-spread variability prior
    exit_spread_sigma_prior_mean =
      priors$spread_sigma$mean,
    
    exit_spread_sigma_prior_sd =
      priors$spread_sigma$sd,
    
    # observation-error prior
    count_dispersion_prior_mean =
      priors$count_dispersion$mean,
    
    count_dispersion_prior_sd =
      priors$count_dispersion$sd
  )
  
  list(
    stan_data = stan_data,
    day_stand = day_stand,
    year_lookup = year_lookup,
    reach_lookup = reach_lookup
  )
}
