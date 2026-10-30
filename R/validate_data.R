#' Validate spawnBayes input data
#'
#' Validates and standardizes survey data for analysis with
#' \code{spawnBayes}. Required fields are checked, dates are
#' converted to \code{Date} format, observer efficiency and
#' coverage values are standardized to proportions, and optional
#' survey-error group classifications are validated.
#'
#' @param data Input data frame. Required columns are
#'   \code{date} and \code{spawner_counts}. Optional columns
#'   include \code{reach}, \code{observer_efficiency},
#'   \code{coverage}, and \code{survey_error_group}.
#'
#' @return A validated and standardized data frame.
#'
#' @details
#' If \code{observer_efficiency} or \code{coverage} are supplied
#' as percentages, they are automatically converted to
#' proportions. Missing values in these columns are assumed to
#' equal 1 and generate a warning.
#'
#' If supplied, \code{survey_error_group} is treated as a
#' categorical grouping variable identifying observations that
#' may differ in observation error. Categories containing fewer
#' than 10 observations generate a warning because group-specific
#' observation-error estimates may be poorly informed.
#' 
#' The function also evaluates annual run-timing patterns for
#' evidence of multiple major peaks. A warning is generated if
#' potentially multimodal run timing is detected because
#' spawnBayes assumes a single seasonal peak within each
#' reach and year.
#'
#' @export
validate_data <- function(data) {
  
  if (!is.data.frame(data))
    stop("data must be a data.frame.", call. = FALSE)
  
  required_cols <- c("date", "spawner_counts")
  
  if (!"reach" %in% names(data))
    data$reach <- "Reach 1"
  
  if (any(is.na(data$reach)))
    stop(
      "reach contains missing values.",
      call. = FALSE
    )
  
  data$reach <- trimws(
    as.character(data$reach)
  )
  
  if (any(data$reach == ""))
    stop(
      "reach contains blank values.",
      call. = FALSE
    )
  
  data$reach <- factor(data$reach)
  
  missing_cols <- setdiff(required_cols, names(data))
  
  if (length(missing_cols) > 0)
    stop(paste0("Missing required column(s): ", paste(missing_cols, collapse = ", ")), call. = FALSE)
  
  if (!inherits(data$date, "Date")) {
    
    data$date <- suppressWarnings(
      lubridate::parse_date_time(
        data$date,
        orders = c(
          "ymd",
          "mdy",
          "dmy",
          "d-b-y",
          "d-b-Y",
          "d B y",
          "d B Y"
        )
      )
    )
    
    data$date <- as.Date(data$date)
    
    if (any(is.na(data$date)))
      stop(
        "date could not be converted to Date format.",
        call. = FALSE
      )
    
  }
  if (length(unique(data$date)) < 2)
    stop("At least two survey dates are required.", call. = FALSE)
  
  if (!is.numeric(data$spawner_counts))
    stop("spawner_counts must be numeric.", call. = FALSE)
  
  if (any(is.na(data$spawner_counts)))
    stop("spawner_counts contains missing values.", call. = FALSE)
  
  if (any(data$spawner_counts < 0))
    stop("spawner_counts cannot be negative.", call. = FALSE)
  
  if (all(data$spawner_counts == 0))
    stop("All spawner_counts are zero.", call. = FALSE)
  
  if (any(data$spawner_counts > 1e5))
    warning("Some spawner_counts exceed 100,000. Check that counts were entered correctly.", call. = FALSE)
  
  if (any(data$date > Sys.Date()))
    warning("Some survey dates occur in the future.", call. = FALSE)
  
  if (any(lubridate::year(data$date) < 1930))
    warning("Some survey dates occur before 1930. Check that dates were imported correctly.", call. = FALSE)
  
  year_counts <- data |>
    dplyr::mutate(year = lubridate::year(date)) |>
    dplyr::count(year, reach)
  
  if (any(year_counts$n < 3))
    warning("Some reach-years contain fewer than three surveys.", call. = FALSE)
  
  if (length(unique(lubridate::year(data$date))) < 2)
    warning("Only one year of data supplied. Data-derived priors may be unreliable.", call. = FALSE)
  
  dup <- any(
    duplicated(
      data[c("reach", "date")]
    )
  )
  
  if (dup)
    warning(
      "Duplicate survey dates detected within one or more reaches.",
      call. = FALSE
    )
  
  if (!"observer_efficiency" %in% names(data))
    data$observer_efficiency <- 1
  
  if (!"coverage" %in% names(data))
    data$coverage <- 1
  
  # Convert percent strings to numeric
  if (is.character(data$observer_efficiency))
    data$observer_efficiency <-
    as.numeric(gsub("%", "", data$observer_efficiency))
  
  if (is.character(data$coverage))
    data$coverage <-
    as.numeric(gsub("%", "", data$coverage))
  
  # Convert percentages to proportions
  if (max(data$observer_efficiency, na.rm = TRUE) > 1)
    data$observer_efficiency <-
    data$observer_efficiency / 100
  
  if (max(data$coverage, na.rm = TRUE) > 1)
    data$coverage <-
    data$coverage / 100
  
  # Assume missing values equal 1
  if (any(is.na(data$observer_efficiency))) {
    
    warning(
      "Missing observer_efficiency values were assumed to equal 1.",
      call. = FALSE
    )
    
    data$observer_efficiency[
      is.na(data$observer_efficiency)
    ] <- 1
    
  }
  
  if (any(is.na(data$coverage))) {
    
    warning(
      "Missing coverage values were assumed to equal 1.",
      call. = FALSE
    )
    
    data$coverage[
      is.na(data$coverage)
    ] <- 1
    
  }
  
  if (any(
    data$observer_efficiency <= 0 |
    data$observer_efficiency > 1
  ))
    stop(
      "observer_efficiency must be between 0 and 1.",
      call. = FALSE
    )
  
  if (any(
    data$coverage <= 0 |
    data$coverage > 1
  ))
    stop(
      "coverage must be between 0 and 1.",
      call. = FALSE
    )
  
  # Survey error groups
  
  has_error_groups <- "survey_error_group" %in% names(data)
  
  if (!has_error_groups)
    data$survey_error_group <- "default"
  
  if (any(is.na(data$survey_error_group)))
    stop(
      "survey_error_group contains missing values.",
      call. = FALSE
    )
  
  data$survey_error_group <- trimws(
    as.character(data$survey_error_group)
  )
  
  if (any(data$survey_error_group == ""))
    stop(
      "survey_error_group contains blank values.",
      call. = FALSE
    )
  
  data$survey_error_group <- factor(
    data$survey_error_group
  )
  
  if (has_error_groups) {
    
    group_counts <- table(
      data$survey_error_group
    )
    
    if (any(group_counts < 10)) {
      
      sparse_groups <- paste(
        names(group_counts)[group_counts < 10],
        group_counts[group_counts < 10],
        sep = " = ",
        collapse = ", "
      )
      
      warning(
        paste0(
          "Some survey_error_group categories contain fewer than ",
          "10 observations (",
          sparse_groups,
          "). Consider combining sparse categories."
        ),
        call. = FALSE
      )
      
    }
    
  }
  
  year_modes <- identify_multimodal_years(data)
  
  n_multimodal <- sum(year_modes$multimodal)
  
  if (n_multimodal > 0)
    warning(
      paste0(
        "Potential multimodal run timing detected in ",
        n_multimodal,
        " reach-years. spawnBayes assumes a single run peak ",
        "within each reach and year."
      ),
      call. = FALSE
    )
  
  data
}