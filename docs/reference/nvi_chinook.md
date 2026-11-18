# Northwest Vancouver Island Chinook spawner survey data

Spawner survey observations from Artlish River, Kaouk River, and Tahsish
River collected by Fisheries and Oceans Canada's South Coast Stock
Assessment.

## Format

A data frame containing spawner survey observations with the following
variables:

- date:

  Survey date.

- stream:

  Survey stream identifier. Identical to group in this dataset.

- group:

  Population or river name.

- spawner_counts:

  Observed salmon count.

- observer_efficiency:

  Estimated observer efficiency.

- survey_error_group:

  Survey type or survey quality grouping variable.

## Source

Fisheries and Oceans Canada NuSEDS database.

## Details

The dataset is used in the spawnBayes vignettes to demonstrate both
single-population and multi-population abundance estimation.

## Examples

``` r
data(nvi_chinook)
head(nvi_chinook)
#> # A tibble: 6 × 6
#>   date       stream  group spawner_counts observer_efficiency survey_error_group
#>   <date>     <chr>   <chr>          <dbl>               <dbl> <chr>             
#> 1 2007-09-20 ARTLIS… ARTL…            121               0.950 HIGH              
#> 2 2007-10-01 ARTLIS… ARTL…            215               0.6   MED               
#> 3 2008-09-12 ARTLIS… ARTL…            196               0.934 HIGH              
#> 4 2008-10-01 ARTLIS… ARTL…            137               1     UNKNOWN           
#> 5 2008-10-10 ARTLIS… ARTL…             75               0.933 HIGH              
#> 6 2008-10-27 ARTLIS… ARTL…              1               1     UNKNOWN           
```
