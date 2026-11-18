# Plot imported NuSEDS survey data

Plot raw survey observations imported from NuSEDS.

## Usage

``` r
plot_nuseds(data, y_scale = c("none", "log10"))
```

## Arguments

- data:

  A data frame produced by
  [`read_nuseds()`](https://sire-p.github.io/spawnBayes/reference/read_nuseds.md).

- y_scale:

  Scale used for the y-axis. One of `"none"` or `"log10"`.

## Value

A ggplot object showing survey observations by year.

## Details

This function is intended as a quick quality-control step before fitting
a spawnBayes model. Survey counts are plotted through time and coloured
by group.

Inspection-level imports produce one group per stream, while
segment-level imports produce one group per NuSEDS segment.
