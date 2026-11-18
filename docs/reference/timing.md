# Extract timing estimates

Extract annual group-specific timing estimates from a fitted spawnBayes
model.

## Usage

``` r
timing(fit, CI = c(66, 95), format = c("yday", "date"))
```

## Arguments

- fit:

  A fitted spawnBayes model.

- CI:

  Credible interval widths to report.

- format:

  Either `"yday"` or `"date"`.

## Value

A named list containing group-specific annual timing estimates for:

- arrival_peak:

  Peak arrival timing

- arrival_spread:

  Arrival spread

- effective_residence:

  Effective residence time

- exit_lag:

  Exit lag

- exit_spread:

  Exit spread
