# Create a spawnBayes data template

Create a csv template illustrating the expected input data structure for
spawnBayes.

## Usage

``` r
template_file(file = "spawnBayes_template.csv")
```

## Arguments

- file:

  Output file name.

## Value

The path to the created file.

## Details

The template includes commonly used columns for survey date, group
identity (e.g., reach, stream, population), observed spawner counts,
observer efficiency, survey coverage, and survey-error classification.

The template contains a minimal working example suitable for fitting a
spawnBayes model.

The `group` column identifies the unit for which abundance is estimated
and timing is allowed to vary. Groups may represent reaches, streams,
rivers, populations, index areas, or other biologically meaningful
survey units.

Observer efficiency and coverage should be supplied as proportions
ranging from 0 to 1.
