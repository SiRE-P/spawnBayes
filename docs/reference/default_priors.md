# Default prior specification

Create a default prior specification for spawnBayes.

## Usage

``` r
default_priors(
  data,
  abundance = NULL,
  assumed_residence = NULL,
  arrival_peak = NULL,
  arrival_quantile = 0.4
)
```

## Arguments

- data:

  A data frame containing survey observations.

- abundance:

  Expected spawner abundance. May be a single value applied to all
  groups or a named vector containing separate values for each group. If
  NULL, group-specific values are estimated from the observed survey
  counts.

- assumed_residence:

  Assumed mean residence time (days). If supplied, this value is used to
  define the residence-time prior. If NULL, a default prior is used.

- arrival_peak:

  Expected peak arrival date. If NULL, a default value is estimated
  using the survey-date quantile specified by `arrival_quantile`.

- arrival_quantile:

  Quantile of survey dates used to estimate a default arrival peak date
  when `arrival_peak` is NULL. Ignored when `arrival_peak` is supplied.

## Value

A list containing prior specifications.

## Details

Default priors are partially informed by the survey design. When
`arrival_peak` is not supplied, the prior mean is estimated from the
survey-date quantile specified by `arrival_quantile`.

The default arrival-spread prior is derived from the median annual
survey span (difference between the first and last survey dates within
years). The prior mean is approximated as one-sixth of the median survey
span, reflecting the assumption that survey windows encompass arrival,
residence, departure, and additional buffer periods before and after the
run.
