# Plot fitted run curves

Plot posterior estimates of spawners present through time against survey
observations for each year.

## Usage

``` r
plot_run_curve(
  fit,
  CI = c(66, 95),
  outlier_p_thresh = 0.25,
  y_scale = c("none", "log10"),
  facet = c("year", "group_year"),
  groups = NULL
)
```

## Arguments

- fit:

  A fitted spawnBayes model.

- CI:

  Numeric vector of credible interval widths to plot. Multiple intervals
  may be supplied (e.g., `c(66, 95)`).

- outlier_p_thresh:

  Probability threshold used to classify surveys as potential outliers.

- y_scale:

  Scale used for the y-axis. One of `"none"` or `"log10"`.

- facet:

  Plot layout. One of:

  "year"

  :   One panel per year with groups overlaid.

  "group_year"

  :   Separate panels for each group-year combination.

- groups:

  Optional character vector specifying a subset of groups to include in
  the plot.

## Value

A ggplot object showing fitted run curves and corrected survey counts.

## Details

When multiple groups are present, fitted curves and observations are
coloured by group.

Surveys with posterior outlier probabilities exceeding
`outlier_p_thresh` are shown as open circles.

Survey observations are plotted after deterministic correction for
observer efficiency and survey coverage to facilitate comparison with
the estimated number of spawners present.
