#' Import NuSEDS stream inspection log exports
#'
#' Import one or more NuSEDS stream inspection log exports
#' and convert them to a format suitable for spawnBayes.
#'
#' The importer currently supports NuSEDS exports from the
#' stream inspection logs view and expects data on a worksheet
#' named `"Data"`.
#'
#' Two import levels are supported:
#'
#' * `"inspection"` uses inspection-level abundance estimates
#'   (`IS-Total Live Adults Estimated`) and treats streams as
#'   the grouping variable.
#'
#' * `"segment"` uses segment-level abundance estimates
#'   (`SG-Total Live Adults Estimated`) and treats segments as
#'   the grouping variable.
#'
#' Observer efficiency is calculated automatically from the
#' observed and estimated counts when available.
#'
#' @param file Path to one or more NuSEDS Excel files.
#' @param level Either `"inspection"` or `"segment"`.
#'
#' @return A data frame suitable for use with
#'   [fit_spawner()].
#'
#' @export
read_nuseds <- function(
    file,
    level = c("inspection", "segment")
) {
  
  level <- match.arg(level)
  
  dat <- purrr::map_dfr(
    file,
    function(f) {
      
      sheets <- readxl::excel_sheets(f)
      
      if (!"Data" %in% sheets)
        stop(
          paste0(
            basename(f),
            " does not contain a worksheet named 'Data'."
          ),
          call. = FALSE
        )
      
      x <- readxl::read_excel(
        path = f,
        sheet = "Data"
      )
      
      x$source_file <- basename(f)
      
      x
      
    }
  )
  
  if (level == "inspection") {
    
    dat <- dat |>
      dplyr::transmute(
        
        date =
          as.Date(`Inspection Start Date`),
        
        stream =
          as.character(Stream),
        
        # spawnBayes currently expects a reach column
        reach =
          as.character(Stream),
        
        spawner_counts =
          `IS-Total Live Adults Estimated`,
        
        observer_efficiency =
          dplyr::if_else(
            is.na(`IS-Total Live Adults Observed`) |
              is.na(`IS-Total Live Adults Estimated`) |
              `IS-Total Live Adults Estimated` <= 0,
            1,
            pmin(
              `IS-Total Live Adults Observed` /
                `IS-Total Live Adults Estimated`,
              1
            )
          ),
        
        survey_error_group =
          as.character(`Reliability of Inspection`)
      ) |>
      
      # Inspection-level totals are commonly repeated
      # once for every segment in NuSEDS exports.
      dplyr::distinct(
        stream,
        date,
        .keep_all = TRUE
      )
    
  } else {
    
    dat <- dat |>
      dplyr::transmute(
        
        date =
          as.Date(`Inspection Start Date`),
        
        stream =
          as.character(Stream),
        
        reach =
          as.character(`Segment Name`),
        
        spawner_counts =
          `SG-Total Live Adults Estimated`,
        
        observer_efficiency =
          dplyr::if_else(
            is.na(`SG-Total Live Adults Observed`) |
              is.na(`SG-Total Live Adults Estimated`) |
              `SG-Total Live Adults Estimated` <= 0,
            1,
            pmin(
              `SG-Total Live Adults Observed` /
                `SG-Total Live Adults Estimated`,
              1
            )
          ),
        
        survey_error_group =
          as.character(`Reliability of Inspection`)
      )
    
  }
  
  dat |>
    dplyr::filter(
      !is.na(date),
      !is.na(spawner_counts),
      spawner_counts > 0
    ) |>
    dplyr::mutate(
      survey_error_group =
        dplyr::if_else(
          is.na(survey_error_group) |
            survey_error_group == "",
          "UNKNOWN",
          survey_error_group
        )
    )
  
}