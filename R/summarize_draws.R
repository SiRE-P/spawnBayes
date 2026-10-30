#' Summarize posterior draws
#'
#' @keywords internal
summarize_draws <- function(draws, lookup, CI = c(66, 95)) {
  
  if (!is.numeric(CI))
    stop("CI must be numeric.", call. = FALSE)
  
  if (any(CI <= 0 | CI >= 100))
    stop(
      "All CI values must be between 0 and 100.",
      call. = FALSE
    )
  
  CI <- sort(unique(round(CI)))
  
  out <- lookup
  
  out$median <- apply(
    draws,
    2,
    median
  )
  
  for (ci in CI) {
    
    alpha <- (1 - ci / 100) / 2
    
    qs <- t(
      apply(
        draws,
        2,
        quantile,
        probs = c(alpha, 1 - alpha)
      )
    )
    
    out[[paste0("lwr_", ci)]] <- qs[, 1]
    out[[paste0("upr_", ci)]] <- qs[, 2]
    
  }
  
  lower_cols <- paste0("lwr_", rev(CI))
  upper_cols <- paste0("upr_", CI)
  
  out <- out[
    ,
    c(
      names(lookup),
      lower_cols,
      "median",
      upper_cols
    )
  ]
  
  numeric_cols <- setdiff(
    names(out),
    names(lookup)
  )
  
  out[numeric_cols] <- round(
    out[numeric_cols]
  )
  
  rownames(out) <- NULL
  
  out
  
}