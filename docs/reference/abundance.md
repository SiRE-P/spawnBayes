# Extract abundance estimates

Extract annual group-specific spawner abundance estimates from a fitted
spawnBayes model.

## Usage

``` r
abundance(fit, CI = c(66, 95), outlier_p_thresh = 0.25)
```

## Arguments

- fit:

  A fitted spawnBayes model.

- CI:

  Credible interval widths to report.

- outlier_p_thresh:

  Probability threshold used to classify surveys as potential outliers
  when reporting annual outlier counts.

## Value

A data frame containing group-specific annual abundance estimates.
Output includes posterior median abundance estimates and credible
intervals. When an assumed residence time was supplied during model
fitting, traditional trapezoidal area-under-the-curve (TAUC) abundance
estimates and the percent difference between the posterior median and
TAUC estimate are also reported.

The output additionally includes a logical `multimodal` flag identifying
group-years with evidence of multiple major run-timing peaks and, when
an outlier observation model was fitted, the number of surveys within
each group-year having posterior outlier probabilities exceeding
`outlier_p_thresh`.
