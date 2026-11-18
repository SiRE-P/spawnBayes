# Validate spawnBayes input data

Validates and standardizes survey data for analysis with `spawnBayes`.
Required fields are checked, dates are converted to `Date` format,
observer efficiency and coverage values are standardized to proportions,
and optional survey-error group classifications are validated.

## Usage

``` r
validate_data(data)
```

## Arguments

- data:

  Input data frame. Required columns are `date` and `spawner_counts`.
  Optional columns include `group`, `observer_efficiency`, `coverage`,
  and `survey_error_group`.

## Value

A validated and standardized data frame.

## Details

If `observer_efficiency` or `coverage` are supplied as percentages, they
are automatically converted to proportions. Missing values in these
columns are assumed to equal 1 and generate a warning.

If supplied, `survey_error_group` is treated as a categorical grouping
variable identifying observations that may differ in observation error.
Categories containing fewer than 10 observations generate a warning
because group-specific observation-error estimates may be poorly
informed.

The function also evaluates annual run-timing patterns for evidence of
multiple major peaks. A warning is generated if potentially multimodal
run timing is detected because spawnBayes assumes a single seasonal peak
within each group and year.
