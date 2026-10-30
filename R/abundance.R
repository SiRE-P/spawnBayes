#' Extract abundance estimates
#'
#' Extract annual reach-specific spawner abundance estimates
#' from a fitted spawnBayes model.
#'
#' @param fit A fitted spawnBayes model.
#' @param CI Credible interval widths to report.
#' @param outlier_p_thresh Probability threshold used to
#'   classify surveys as potential outliers when reporting
#'   annual outlier counts.
#'
#' @return A data frame containing reach-specific annual
#' abundance estimates. Output includes posterior median
#' abundance estimates and credible intervals. When an
#' assumed residence time was supplied during model fitting,
#' traditional trapezoidal area-under-the-curve (TAUC)
#' abundance estimates and the percent difference between
#' the posterior median and TAUC estimate are also reported.
#'
#' The output additionally includes a logical `multimodal`
#' flag identifying reach-years with evidence of multiple
#' major run-timing peaks and, when an outlier observation
#' model was fitted, the number of surveys within each
#' reach-year having posterior outlier probabilities
#' exceeding `outlier_p_thresh`.
#'
#' @export
abundance <- function(
    fit,
    CI = c(66, 95),
    outlier_p_thresh = 0.25
) {
  
  if (!inherits(fit, "spawnBayes_fit"))
    stop(
      "fit must be a spawnBayes_fit object.",
      call. = FALSE
    )
  
  log_run_draws <- fit$fit$draws(
    "log_run",
    format = "matrix"
  )
  
  abundance_draws <- exp(log_run_draws)
  
  out <- summarize_draws(
    draws = abundance_draws,
    lookup = fit$stan_inputs$log_run_lookup |>
      dplyr::select(
        reach,
        year
      ),
    CI = CI
  )
  
  out <- dplyr::left_join(
    out,
    fit$multimodal_years |>
      dplyr::select(
        reach,
        year,
        multimodal
      ),
    by = c(
      "reach",
      "year"
    )
  )
  
  outlier_prob <- try(
    fit$fit$summary("p_is_outlier"),
    silent = TRUE
  )
  
  if (!inherits(outlier_prob, "try-error")) {
    
    outlier_years <-
      data.frame(
        reach = fit$data$reach,
        year = lubridate::year(fit$data$date),
        p_is_outlier = outlier_prob$mean
      ) |>
      dplyr::group_by(
        reach,
        year
      ) |>
      dplyr::summarise(
        n_outliers =
          sum(
            p_is_outlier > outlier_p_thresh
          ),
        .groups = "drop"
      )
    
    out <-
      dplyr::left_join(
        out,
        outlier_years,
        by = c(
          "reach",
          "year"
        )
      )
    
  } else {
    
    out$n_outliers <- NA_integer_
    
  }
  
  if (!is.null(fit$TAUC)) {
    
    out <- dplyr::left_join(
      out,
      fit$TAUC,
      by = c(
        "reach",
        "year"
      )
    )
    
    out$pct_diff_TAUC <- ifelse(
      is.na(out$TAUC) | out$TAUC == 0,
      NA_real_,
      round(
        100 * (out$median - out$TAUC) / out$TAUC,
        1
      )
    )
    
  }
  
  out <- out |>
    dplyr::select(
      reach,
      year,
      median,
      dplyr::starts_with("lwr"),
      dplyr::starts_with("upr"),
      dplyr::any_of(
        c(
          "TAUC",
          "pct_diff_TAUC"
        )
      ),
      multimodal,
      n_outliers
    ) |>
    dplyr::arrange(
      reach,
      year
    )
  
  out
  
}