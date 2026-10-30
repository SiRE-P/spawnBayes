#' Create Stan initial values
#'
#' @keywords internal
make_inits <- function(stan_data) {
  
  list(
    
    # abundance
    log_run =
      matrix(
        stats::rnorm(
          stan_data$n_years * stan_data$n_reaches,
          mean = log(stan_data$abundance_prior_mean),
          sd = 0.5
        ),
        nrow = stan_data$n_years,
        ncol = stan_data$n_reaches,
        byrow = TRUE
      ),
    
    # timing means
    timing_mu = c(
      stats::rnorm(
        1,
        stan_data$arrival_prior_mean,
        stan_data$arrival_prior_sd / 2
      ),
      stats::rnorm(
        1,
        stan_data$spread_prior_mean,
        stan_data$spread_prior_sd / 2
      ),
      stats::rnorm(
        1,
        stan_data$exit_lag_prior_mean,
        stan_data$exit_lag_prior_sd / 2
      ),
      stats::rnorm(
        1,
        stan_data$spread_prior_mean,
        stan_data$spread_prior_sd / 2
      )
    ),
    
    # year-level timing variation
    timing_sigma_year = c(
      stan_data$arrival_sigma_prior_mean,
      stan_data$arrival_spread_sigma_prior_mean,
      stan_data$exit_lag_sigma_prior_mean,
      stan_data$exit_spread_sigma_prior_mean
    ),
    
    # reach-level timing variation
    timing_sigma_reach = c(
      stan_data$arrival_sigma_prior_mean,
      stan_data$arrival_spread_sigma_prior_mean,
      stan_data$exit_lag_sigma_prior_mean,
      stan_data$exit_spread_sigma_prior_mean
    ),
    
    # non-centred year effects
    year_timing_raw =
      matrix(
        stats::rnorm(
          stan_data$n_years * 4,
          0,
          0.1
        ),
        nrow = stan_data$n_years,
        ncol = 4
      ),
    
    # non-centred reach-year deviations
    timing_dev_raw =
      array(
        stats::rnorm(
          stan_data$n_years *
            stan_data$n_reaches *
            4,
          0,
          0.1
        ),
        dim = c(
          stan_data$n_years,
          stan_data$n_reaches,
          4
        )
      ),
    
    # initialize correlations near identity
    L_Omega_year = diag(4),
    
    L_Omega_reach = diag(4),
    
    # observation error
    live_phi =
      rep(
        exp(stan_data$count_dispersion_prior_mean),
        stan_data$n_survey_error_groups
      ),
    
    # outlier model
    p_outlier = 0.05,
    
    outlier_multiplier = 10
  )
  
}