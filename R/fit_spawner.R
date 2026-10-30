#' Fit a spawner abundance model
#'
#' Fit the spawnBayes model to repeated spawner-count surveys.
#'
#' The input data must contain a `date` column and a
#' `spawner_counts` column.
#'
#' Optional `reach`, `observer_efficiency`, `coverage`, and
#' `survey_error_group` columns may also be supplied.
#' If omitted, observer efficiency and coverage are
#' assumed to equal 1 and all observations are assigned
#' to a common survey-error group.
#' 
#'  When a reach column is supplied, spawnBayes fits
#' a hierarchical multi-reach timing model in which
#' timing information is shared among reaches within
#' years while abundance is estimated separately for
#' each reach.
#'
#' When a `survey_error_group` column is provided,
#' spawnBayes estimates separate observation-dispersion
#' parameters for each group. This can be used to account
#' for differences in survey quality, survey method, or
#' other factors expected to influence observation error.
#' 
#' If `outlier_model = TRUE`, spawnBayes uses a mixture
#' observation model that allows a small proportion of surveys
#' to arise from a higher-variance observation process. This
#' reduces the influence of anomalous observations on model
#' fitting and provides posterior probabilities of outlier
#' status for each survey.
#'
#'
#' @param data A data frame containing survey observations.
#'   Required columns are `date` and `spawner_counts`.
#'   Optional columns include `reach`, `observer_efficiency`,
#'   `coverage`, and `survey_error_group`.
#' @param abundance Prior estimate of spawner abundance.
#'   For multi-reach analyses this may be supplied separately
#'   for each reach. If NULL, default values are estimated
#'   from the observed counts.
#' @param assumed_residence Assumed mean residence time (days), also known as survey life.
#'   If supplied, this value is used to construct the residence-time
#'   prior and to calculate traditional trapezoidal area under the curve (TAUC)
#'   abundance estimates. If NULL, the default spawnBayes residence-time prior
#'   is used and TAUC estimates are not calculated.
#' @param arrival_peak Expected peak arrival date. If NULL,
#'   a default value is estimated using the survey-date
#'   quantile specified by `arrival_quantile`.
#' @param arrival_quantile Quantile of survey dates used to estimate
#'   a default arrival peak date when `arrival_peak` is NULL.
#'   Ignored when `arrival_peak` is supplied.
#' @param trim_zeros Logical. Remove repeated leading and trailing
#'   zero-count surveys within years while retaining a single zero
#'   on either side of the run.
#' @param outlier_model Logical. If TRUE, a robust observation
#'   model is used in which a small proportion of surveys may
#'   arise from a higher-variance observation process. This
#'   reduces the influence of anomalous surveys on model fitting.
#' @param priors Additional model priors produced by
#'   [default_priors()].
#' @param chains Number of MCMC chains.
#' @param iter_warmup Number of warmup iterations per chain.
#' @param iter_sampling Number of post-warmup iterations per chain.
#' @param adapt_delta Stan adaptation target acceptance rate.
#' @param refresh refresh Frequency of CmdStan progress updates.
#'
#' @return A `spawnBayes_fit` object containing the fitted
#' model, processed survey data, annual TAUC estimates when
#' available, and run-timing diagnostic information including
#' potential multimodal years.
#'
#' @export
fit_spawner <- function(
    data,
    abundance = NULL,
    assumed_residence = NULL,
    arrival_peak = NULL,
    arrival_quantile = 0.4,
    trim_zeros = TRUE,
    outlier_model = TRUE,
    priors = NULL,
    chains = 4,
    iter_warmup = 1000,
    iter_sampling = 1000,
    refresh = 100, 
    adapt_delta = 0.95
) {
  
  trim_repeated_zeros <- function(x) {
    
    pos <- which(x > 0)
    
    if (length(pos) == 0)
      return(rep(TRUE, length(x)))
    
    first_pos <- min(pos)
    last_pos <- max(pos)
    
    keep <- rep(TRUE, length(x))
    
    # Keep at most one leading zero
    if (first_pos > 2)
      keep[1:(first_pos - 2)] <- FALSE
    
    # Keep at most one trailing zero
    if (last_pos < (length(x) - 1))
      keep[(last_pos + 2):length(x)] <- FALSE
    
    keep
    
  }
  
  if (!is.null(assumed_residence)) {
    
    if (!is.numeric(assumed_residence) ||
        length(assumed_residence) != 1 ||
        assumed_residence <= 1)
      stop(
        "assumed_residence must be a single numeric value greater than 1.",
        call. = FALSE
      )
    
  }
  
  data <- validate_data(data)
  
  multimodal_years <- identify_multimodal_years(data)
  
  if (trim_zeros) {
    
    n_before <- nrow(data)
    
    data <- data |>
      mutate(year = lubridate::year(date)) |>
      group_by(year, reach) |>
      arrange(date, .by_group = TRUE) |>
      filter(trim_repeated_zeros(spawner_counts)) |>
      dplyr::ungroup() |>
      dplyr::select(-year)
    
    n_removed <- n_before - nrow(data)
    
    if (n_removed > 0)
      message(
        n_removed,
        " repeated leading/trailing zero-count surveys removed."
      )
    
  }
  
  data$spawner_counts_uncorrected <- data$spawner_counts
  
  data <- data |>
    dplyr::mutate(
      spawner_counts =
        spawner_counts /
        observer_efficiency /
        coverage
    )
  
  TAUC <- compute_TAUC(
    data = data,
    assumed_residence = assumed_residence
  )
  
  if (is.null(priors))
    priors <- default_priors(
      data = data,
      abundance = abundance,
      assumed_residence = assumed_residence,
      arrival_peak = arrival_peak,
      arrival_quantile = arrival_quantile
    )
  
  stan_inputs <- make_stan_data(
    data = data,
    priors = priors,
    outlier_model = outlier_model
  )
  
  stan_file <- system.file(
    "stan",
    "spawnBayes.stan",
    package = "spawnBayes"
  )
  
  mod <- cmdstanr::cmdstan_model(stan_file)
  
  fit <- mod$sample(
    data = stan_inputs$stan_data,
    init = function() make_inits(stan_inputs$stan_data),
    chains = chains,
    parallel_chains = chains,
    iter_warmup = iter_warmup,
    iter_sampling = iter_sampling,
    adapt_delta = adapt_delta, 
    refresh = refresh
  )
  
  structure(
    list(
      fit = fit,
      data = data,
      priors = priors,
      stan_inputs = stan_inputs,
      assumed_residence = assumed_residence,
      TAUC = TAUC,
      survey_error_groups = levels(data$survey_error_group),
      outlier_model = outlier_model,
      multimodal_years = multimodal_years
    ),
    class = "spawnBayes_fit"
  )
  
}
