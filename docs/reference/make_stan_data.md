# Construct Stan data for spawnBayes

Convert validated survey data and prior specifications into the data
list required by the spawnBayes Stan model.

## Usage

``` r
make_stan_data(data, priors, outlier_model = TRUE)
```

## Arguments

- data:

  A validated data frame containing survey observations.

- priors:

  A prior specification object returned by
  [`default_priors()`](https://sire-p.github.io/spawnBayes/reference/default_priors.md).

- outlier_model:

  Logical. If TRUE, include the outlier observation model in the Stan
  data passed to spawnBayes.

## Value

A list containing:

- stan_data:

  Data list supplied to Stan.

- day_stand:

  Reference day used for day standardization.

- year_lookup:

  Mapping between Stan year indices and calendar years.

- group_lookup:

  Mapping between Stan group indices and group names.

- log_run_lookup:

  Mapping between Stan log_run indices and year-group combinations.
