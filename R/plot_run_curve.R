#' Plot fitted run curves
#'
#' Plot posterior estimates of spawners present through time
#' against observed survey counts for each year.
#'
#' When multiple reaches are present, fitted curves and
#' observations are coloured by reach.
#'
#' Surveys with posterior outlier probabilities exceeding
#' 0.25 are shown as open circles.
#'
#' Corrected survey counts used to fit the model are shown as
#' points. If observer-efficiency or coverage corrections
#' were applied, the original uncorrected survey counts are
#' shown as open circles with grey outlines.
#'
#' @param fit A fitted spawnBayes model.
#' @param CI Numeric vector of credible interval widths to plot.
#'   Multiple intervals may be supplied (e.g., `c(66, 95)`).
#'
#' @return A ggplot object showing fitted run curves and
#' observed survey counts by year.
#'
#' @export
plot_run_curve <- function(fit, CI = c(66, 95)) {
  
  if (!inherits(fit, "spawnBayes_fit"))
    stop(
      "fit must be a spawnBayes_fit object.",
      call. = FALSE
    )
  
  if (!is.numeric(CI))
    stop(
      "CI must be numeric.",
      call. = FALSE
    )
  
  if (any(CI <= 0 | CI >= 100))
    stop(
      "All CI values must be between 0 and 100.",
      call. = FALSE
    )
  
  CI <- sort(unique(CI), decreasing = TRUE)
  
  lookup <- fit$stan_inputs$log_run_lookup
  
  day_stand <- fit$stan_inputs$day_stand
  
  max_day <- max(
    fit$stan_inputs$stan_data$day
  )
  
  arrival <- fit$fit$draws(
    "arrival",
    format = "matrix"
  )
  
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
  
  log_run <- fit$fit$draws(
    "log_run",
    format = "matrix"
  )
  
  stopifnot(
    nrow(lookup) == ncol(log_run)
  )
  
  spawn_curves <- vector(
    "list",
    ncol(log_run)
  )
  
  for (j in seq_len(ncol(log_run))) {
    
    live <- sapply(
      -5:max_day,
      function(x) {
        
        entered <- stats::pnorm(
          x,
          arrival[, j],
          arrival_spread[, j]
        )
        
        exited <- stats::pnorm(
          x,
          arrival[, j] + exit_lag[, j],
          exit_spread[, j]
        )
        
        exp(
          log_run[, j] +
            log(
              pmax(
                entered * (1 - exited),
                1e-8
              )
            )
        )
        
      }
    )
    
    curve_dat <- data.frame(
      reach = lookup$reach[j],
      year = lookup$year[j],
      day = (-5:max_day) + day_stand,
      fish = apply(
        live,
        2,
        median
      )
    )
    
    for (ci in CI) {
      
      alpha <- (1 - ci / 100) / 2
      
      curve_dat[[paste0("lower_", ci)]] <-
        apply(
          live,
          2,
          stats::quantile,
          probs = alpha
        )
      
      curve_dat[[paste0("upper_", ci)]] <-
        apply(
          live,
          2,
          stats::quantile,
          probs = 1 - alpha
        )
      
    }
    
    spawn_curves[[j]] <- curve_dat
    
  }
  
  spawn_curves <- dplyr::bind_rows(
    spawn_curves
  )
  
  obs <- fit$data |>
    dplyr::mutate(
      year = lubridate::year(date),
      day = lubridate::yday(date)
    )
  
  outlier_prob <- try(
    fit$fit$summary("p_is_outlier"),
    silent = TRUE
  )
  
  obs$p_is_outlier <-
    if (!inherits(outlier_prob, "try-error")) {
      outlier_prob$mean
    } else {
      rep(0, nrow(obs))
    }
  
  obs$outlier_flag <-
    obs$p_is_outlier > 0.25
  
  show_uncorrected <-
    "spawner_counts_uncorrected" %in% names(obs) &&
    any(
      obs$spawner_counts_uncorrected !=
        obs$spawner_counts
    )
  
  p <- ggplot2::ggplot(
    spawn_curves,
    ggplot2::aes(
      x = day,
      y = fish,
      colour = reach,
      fill = reach
    )
  )
  
  ribbon_alpha <- seq(
    0.15,
    0.40,
    length.out = length(CI)
  )
  
  for (k in seq_along(CI)) {
    
    ci <- CI[k]
    
    p <- p +
      ggplot2::geom_ribbon(
        ggplot2::aes(
          ymin = .data[[paste0("lower_", ci)]],
          ymax = .data[[paste0("upper_", ci)]]
        ),
        alpha = ribbon_alpha[k],
        colour = NA
      )
    
  }
  
  p <- p +
    ggplot2::geom_line(
      linewidth = 0.8
    ) +
    ggplot2::geom_point(
      data = obs,
      ggplot2::aes(
        x = day,
        y = spawner_counts,
        colour = reach,
        shape = outlier_flag
      ),
      inherit.aes = FALSE,
      size = 2
    ) +
    ggplot2::scale_shape_manual(
      values = c(
        `FALSE` = 16,
        `TRUE` = 1
      ),
      labels = c(
        `FALSE` = "Survey",
        `TRUE` = "Potential outlier"
      ),
      name = NULL
    )
  
  if (show_uncorrected) {
    
    p <- p +
      ggplot2::geom_point(
        data = obs,
        ggplot2::aes(
          x = day,
          y = spawner_counts_uncorrected
        ),
        inherit.aes = FALSE,
        shape = 1,
        colour = "grey40",
        size = 2
      ) +
      ggplot2::labs(
        caption = paste(
          "Grey open circles show uncorrected survey counts.",
          "Coloured points show counts after observer-efficiency and coverage corrections."
        )
      )
    
  }
  
  p +
    ggplot2::facet_wrap(
      ~year,
      scales = "free_y"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      strip.background =
        ggplot2::element_blank(),
      panel.grid.minor =
        ggplot2::element_blank()
    ) +
    ggplot2::scale_y_continuous(
      labels = scales::label_number(
        scale_cut = scales::cut_short_scale()
      ),
      name = "Spawners present"
    ) +
    ggplot2::scale_x_continuous(
      labels = function(x)
        format(
          as.Date(
            x,
            origin = "2023-12-31"
          ),
          "%b"
        ),
      name = NULL
    )
  
}