#' Extract timing estimates
#'
#' Extract annual reach-specific timing estimates from a fitted
#' spawnBayes model.
#'
#' @param fit A fitted spawnBayes model.
#' @param CI Credible interval widths to report.
#' @param format Either `"yday"` or `"date"`.
#'
#' @return A named list containing reach-specific annual timing
#' estimates for:
#' \describe{
#'   \item{arrival_peak}{Peak arrival timing}
#'   \item{arrival_spread}{Arrival spread}
#'   \item{effective_residence}{Effective residence time}
#'   \item{exit_lag}{Exit lag}
#'   \item{exit_spread}{Exit spread}
#' }
#'
#' @export
timing <- function(
    fit,
    CI = c(66, 95),
    format = c("yday", "date")
) {
  
  if (!inherits(fit, "spawnBayes_fit"))
    stop(
      "fit must be a spawnBayes_fit object.",
      call. = FALSE
    )
  
  format <- match.arg(format)
  
  lookup <- fit$stan_inputs$log_run_lookup |>
    dplyr::select(
      reach,
      year
    )
  
  arrival <- fit$fit$draws(
    "arrival",
    format = "matrix"
  )
  
  arrival_peak <-
    arrival +
    fit$stan_inputs$day_stand
  
  arrival_spread <- fit$fit$draws(
    "arrival_spread",
    format = "matrix"
  )
  
  exit_lag <- fit$fit$draws(
    "exit_lag",
    format = "matrix"
  )
  
  exit_spread <- fit$fit$draws(
    "exit_spread",
    format = "matrix"
  )
  
  effective_residence <- matrix(
    NA_real_,
    nrow = nrow(arrival),
    ncol = ncol(arrival)
  )
  
  max_day <- max(
    fit$stan_inputs$stan_data$day
  )
  
  for (j in seq_len(ncol(arrival))) {
    
    live <- sapply(
      seq_len(max_day),
      function(x) {
        
        entered <- stats::pnorm(
          x,
          arrival[, j],
          arrival_spread[, j]
        )
        
        exited <- stats::pnorm(
          x,
          arrival[, j] +
            exit_lag[, j],
          exit_spread[, j]
        )
        
        entered * (1 - exited)
        
      }
    )
    
    effective_residence[, j] <-
      rowSums(live)
    
  }
  
  out <- list(
    
    arrival_peak =
      summarize_draws(
        draws = arrival_peak,
        lookup = lookup,
        CI = CI
      ),
    
    arrival_spread =
      summarize_draws(
        draws = arrival_spread,
        lookup = lookup,
        CI = CI
      ),
    
    effective_residence =
      summarize_draws(
        draws = effective_residence,
        lookup = lookup,
        CI = CI
      ),
    
    exit_lag =
      summarize_draws(
        draws = exit_lag,
        lookup = lookup,
        CI = CI
      ),
    
    exit_spread =
      summarize_draws(
        draws = exit_spread,
        lookup = lookup,
        CI = CI
      )
    
  )
  
  if (format == "date") {
    
    cols <- setdiff(
      names(out$arrival_peak),
      c("reach", "year")
    )
    
    for (col in cols) {
      
      out$arrival_peak[[col]] <- mapply(
        function(year, yday) {
          
          format(
            as.Date(
              yday - 1,
              origin = paste0(year, "-01-01")
            ),
            "%b-%d"
          )
          
        },
        out$arrival_peak$year,
        out$arrival_peak[[col]]
      )
      
    }
    
  }
  
  out
  
}