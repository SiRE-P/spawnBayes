# Compute traditional TAUC abundance estimates

Calculate group-specific annual abundance estimates using the
traditional trapezoidal area-under-the-curve (TAUC) method and an
assumed mean residence time (survey life).

## Usage

``` r
compute_TAUC(data, assumed_residence)
```

## Arguments

- data:

  A data frame containing survey observations.

- assumed_residence:

  Assumed mean residence time (days).

## Value

A data frame containing group-specific annual TAUC abundance estimates.

## Details

The calculation follows the historical TAUC implementation used in
salmon escapement assessments, including half-life adjustments before
the first survey and after the final survey.
