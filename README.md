# spawnBayes <img src="man/figures/logo.png" align="right" height="160"/></a>

`spawnBayes` estimates salmon spawner abundance and run timing from repeated
live-count surveys.Unlike traditional area-under-the-curve (TAUC) approaches,
`spawnBayes` jointly estimates abundance, run timing, effective
residence time, and associated uncertainty using a hierarchical
Bayesian model.

The package supports analyses of individual streams as well as integrated analyses across multiple groups. Groups may represent reaches, streams, rivers, populations, index areas, or other biologically meaningful assessment units. In multi-group analyses, timing information is shared among groups while abundance is estimated separately for each group.

The package is designed to support salmon stock assessment and escapement
monitoring programs. Users provide survey dates and spawner counts and
obtain estimates of annual abundance, run timing, effective residence
time, and associated uncertainty.

## Documentation

Online documentation, function reference pages, and worked tutorials are available at:

[spawnBayes documentation](https://sire-p.github.io/spawnBayes/)

## Installation

```r
# install.packages("remotes")
remotes::install_github("SiRE-P/spawnBayes")
```

## Prerequisites

`spawnBayes` uses `cmdstanr` and requires a local installation of CmdStan.

Install `cmdstanr`:

```r
install.packages(
  "cmdstanr",
  repos = c(
    "https://mc-stan.org/r-packages/",
    getOption("repos")
  )
)
```

Then follow the official CmdStan installation guide:

https://mc-stan.org/docs/cmdstan-guide/installation.html

Verify the installation:

```r
cmdstanr::cmdstan_version()
```

## Data Requirements

Required columns:

| Variable | Description |
|-----------|-------------|
| `date` | Survey date |
| `spawner_counts` | Number of live spawners observed |

Optional columns:

| Variable | Description |
|-----------|-------------|
| `group` | Group identifier (reach, stream, river, population, index area, etc.) |
| `observer_efficiency` | Proportion of fish detected during a survey (0-1) |
| `coverage` | Proportion of spawning habitat surveyed (0-1) |
| `survey_error_group` | Observation-error category used to estimate group-specific observation dispersion |

If `group` is omitted, all observations are assumed to belong to a single
group.

If `observer_efficiency` or `coverage` are omitted, values of 1 are assumed.

If `survey_error_group` is omitted, all observations are assumed to share a
common observation-error distribution.

## What Is a Group?

A group is the unit for which abundance is estimated and timing is allowed
to vary independently.

Groups may represent:

- stream reaches
- streams
- rivers
- populations
- index areas
- other biologically meaningful assessment units

Single-group analyses estimate abundance for one group. Multi-group analyses
share timing information among groups while estimating abundance separately
for each group.

In general, groups should be analysed together when they are expected to
share broad seasonal timing patterns and survey information from one group
may help inform timing estimates in another.

Groups may be analysed separately or jointly. When in doubt, fitting both a single-group and multi-group model can help assess whether shared timing information improves inference.

## Tutorials

The package includes three worked tutorials:

### Getting Started with spawnBayes

Learn how to fit and interpret a single-population model using Artlish River
Chinook salmon data.

[Getting Started with spawnBayes](articles/getting-started.html)

### Multi-Population Analyses in spawnBayes

Fit multiple rivers jointly and share timing information among groups while
estimating abundance separately for each population.

[Multi-Population Analyses in spawnBayes](articles/multi-population.html)

### Importing NuSEDS Data into spawnBayes

Learn how to export data from NuSEDS and import it directly into `spawnBayes`
using `read_nuseds()`.

[Importing NuSEDS Data into spawnBayes](articles/importing-nuseds.html)


## Data Template

Create a template CSV file in the current working directory:

```r
template_file()
```

This creates:

```text
spawnBayes_template.csv
```

containing the required and optional input columns.

## Citation

If you use `spawnBayes` in a publication, please cite:

Thompson, P. L., Akenhead, S. A., and Louie, C. (2026).
*Estimating spawning salmon abundance from visual surveys: a hierarchical
model of arrival and exit dynamics*.
Canadian Journal of Fisheries and Aquatic Sciences, 83, 1-13.
https://doi.org/10.1139/cjfas-2026-0029