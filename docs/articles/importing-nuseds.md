# Importing NuSEDS Data into spawnBayes

``` r
library(spawnBayes)
library(ggplot2)
library(dplyr)
library(lubridate)

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)
```

## Introduction

The read_nuseds() function provides a convenient interface for importing
salmon spawner survey data from NuSEDS spreadsheets into formats
suitable for analysis with spawnBayes. This vignette demonstrates how to
download data from the NuSEDS database and then load it into
`spawnBayes` for analysis.

## Downloading data from NuSEDS

Data can be downloaded directly from the NuSEDS database using the
[NuSEDS Query
Tool](https://pac-salmon.dfo-mpo.gc.ca/Nuseds.Query/#/Query#). You must
be on the DFO network to access this page.

The
[`read_nuseds()`](https://sire-p.github.io/spawnBayes/reference/read_nuseds.md)
function supports two levels of analysis: inspection-level and
segment-level.

### Inspection-level analyses

Inspection-level analyses use stream-level abundance estimates, where
counts are aggregated across all surveyed segments within a stream. In
this case, abundance is estimated separately for each stream, and
streams may be analysed jointly in a hierarchical model.

To download data suitable for:

``` r
read_nuseds(file, level = "inspection")
```

1.  Select **SIL Data (Stream Inspection Logs)** as the data source.
2.  Select the following fields:

``` text
Stream
Inspection Start Date
Reliability of Inspection
IS-Total Live Adults Observed
IS-Total Live Adults Estimated
```

### Segment-level analyses

Segment-level analyses use abundance estimates for individual stream
segments. In this case, abundance is estimated separately for each
segment, and segments may be analysed jointly in a hierarchical model.

To download data suitable for:

``` r
read_nuseds(file, level = "segment")
```

1.  Select **SIL Data (Stream Inspection Logs)** as the data source.
2.  Select the following fields:

``` text
Stream
Inspection Start Date
Segment Name
Reliability of Inspection
SG-Total Live Adults Observed
SG-Total Live Adults Estimated
```

### Importing NuSEDS data

Once a NuSEDS export has been downloaded, it can be imported using
[`read_nuseds()`](https://sire-p.github.io/spawnBayes/reference/read_nuseds.md).

#### Inspection-level example

``` r
spawner_data <- read_nuseds(
  file = "nuseds_export.xlsx",
  level = "inspection"
)

head(spawner_data)
```

#### Segment-level example

``` r
spawner_data <- read_nuseds(
  file = "nuseds_export.xlsx",
  level = "segment"
)

head(spawner_data)
```

The imported dataset can then be validated using:

``` r
spawner_data <- validate_data(spawner_data)
```

and analysed using the standard `spawnBayes` workflow described in the
*Getting Started with spawnBayes* and *Multi-Population Analyses in
spawnBayes* vignettes.
