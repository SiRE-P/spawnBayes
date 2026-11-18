# Import NuSEDS stream inspection log exports

Import one or more NuSEDS stream inspection log exports and convert them
to a format suitable for spawnBayes.

## Usage

``` r
read_nuseds(file, level = c("inspection", "segment"))
```

## Arguments

- file:

  Path to one or more NuSEDS Excel files.

- level:

  Either `"inspection"` or `"segment"`.

## Value

A data frame suitable for use with
[`fit_spawner()`](https://sire-p.github.io/spawnBayes/reference/fit_spawner.md).

## Details

The importer currently supports NuSEDS exports from the stream
inspection logs view and expects data on a worksheet named `"Data"`.

Two import levels are supported:

- `"inspection"` uses inspection-level abundance estimates
  (`IS-Total Live Adults Estimated`) and treats streams as the grouping
  variable.

- `"segment"` uses segment-level abundance estimates
  (`SG-Total Live Adults Estimated`) and treats segments as the grouping
  variable.

Observer efficiency is calculated automatically from the observed and
estimated counts when available.
