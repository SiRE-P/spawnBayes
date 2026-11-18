# Fit a spawner abundance model

Fit the spawnBayes model to repeated spawner-count surveys.

## Usage

``` r
fit_spawner(
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
)
```

## Arguments

- data:

  A data frame containing survey observations. Required columns are
  `date` and `spawner_counts`. Optional columns include `group`,
  `observer_efficiency`, `coverage`, and `survey_error_group`.

- abundance:

  Prior estimate of spawner abundance. For multi-group analyses this may
  be supplied separately for each group. If NULL, default values are
  estimated from the observed counts.

- assumed_residence:

  Assumed mean residence time (days), also known as survey life. If
  supplied, this value is used to construct the residence-time prior and
  to calculate traditional trapezoidal area under the curve (TAUC)
  abundance estimates. If NULL, the default spawnBayes residence-time
  prior is used and TAUC estimates are not calculated.

- arrival_peak:

  Expected peak arrival date. If NULL, a default value is estimated
  using the survey-date quantile specified by `arrival_quantile`.

- arrival_quantile:

  Quantile of survey dates used to estimate a default arrival peak date
  when `arrival_peak` is NULL. Ignored when `arrival_peak` is supplied.

- trim_zeros:

  Logical. Remove repeated leading and trailing zero-count surveys
  within years while retaining a single zero on either side of the run.

- outlier_model:

  Logical. If TRUE, a robust observation model is used in which a small
  proportion of surveys may arise from a higher-variance observation
  process. This reduces the influence of anomalous surveys on model
  fitting.

- priors:

  Additional model priors produced by
  [`default_priors()`](https://sire-p.github.io/spawnBayes/reference/default_priors.md).

- chains:

  Number of MCMC chains.

- iter_warmup:

  Number of warmup iterations per chain.

- iter_sampling:

  Number of post-warmup iterations per chain.

- refresh:

  refresh Frequency of CmdStan progress updates.

- adapt_delta:

  Stan adaptation target acceptance rate.

## Value

A `spawnBayes_fit` object containing the fitted model, processed survey
data, annual TAUC estimates when available, and run-timing diagnostic
information including potential multimodal years.

## Details

The input data must contain a `date` column and a `spawner_counts`
column.

Optional `group`, `observer_efficiency`, `coverage`, and
`survey_error_group` columns may also be supplied. If omitted, observer
efficiency and coverage are assumed to equal 1 and all observations are
assigned to a common survey-error group.

When a group column is supplied (i.e., for different streams, reaches,
populations), spawnBayes fits a hierarchical multi-group timing model in
which timing information is shared among groups within years while
abundance is estimated separately for each group.

When a `survey_error_group` column is provided, spawnBayes estimates
separate observation-dispersion parameters for each group. This can be
used to account for differences in survey quality, survey method, or
other factors expected to influence observation error.

If `outlier_model = TRUE`, spawnBayes uses a mixture observation model
that allows a small proportion of surveys to arise from a
higher-variance observation process. This reduces the influence of
anomalous observations on model fitting and provides posterior
probabilities of outlier status for each survey.
