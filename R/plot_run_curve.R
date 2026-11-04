#' Plot fitted run curves
#'
#' Plot posterior estimates of spawners present through time
#' against survey observations for each year.
#'
#' When multiple groups are present, fitted curves and
#' observations are coloured by group.
#'
#' Surveys with posterior outlier probabilities exceeding
#' `outlier_p_thresh` are shown as open circles.
#'
#' Survey observations are plotted after deterministic
#' correction for observer efficiency and survey coverage
#' to facilitate comparison with the estimated number of
#' spawners present.
#'
#' @param fit A fitted spawnBayes model.
#' @param CI Numeric vector of credible interval widths to plot.
#'   Multiple intervals may be supplied (e.g., `c(66, 95)`).
#' @param outlier_p_thresh Probability threshold used to
#'   classify surveys as potential outliers.
#' @param y_scale Scale used for the y-axis. One of
#'   `"none"` or `"log10"`.
#' @param facet Plot layout. One of:
#'   \describe{
#'     \item{"year"}{One panel per year with groups overlaid.}
#'     \item{"group_year"}{Separate panels for each group-year combination.}
#'   }
#' @param groups Optional character vector specifying a subset
#'   of groups to include in the plot.
#'
#' @return A ggplot object showing fitted run curves and
#' corrected survey counts.
#'
#' @export
plot_run_curve <- function(
    fit,
    CI = c(66, 95),
    outlier_p_thresh = 0.25,
    y_scale = c("none", "log10"),
    facet = c("year", "group_year"),
    groups = NULL
) {
  
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
  
  y_scale <- match.arg(y_scale)
  facet <- match.arg(facet)
  
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
      group = lookup$group[j],
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
      day = lubridate::yday(date),
      spawner_counts =
        spawner_counts /
        observer_efficiency /
        coverage
    )
  
  if (!is.null(groups)) {
    
    missing_groups <- setdiff(
      groups,
      unique(obs$group)
    )
    
    if (length(missing_groups) > 0)
      stop(
        paste(
          "Unknown group(s):",
          paste(missing_groups, collapse = ", ")
        ),
        call. = FALSE
      )
    
    spawn_curves <- spawn_curves |>
      dplyr::filter(
        group %in% groups
      )
    
    obs <- obs |>
      dplyr::filter(
        group %in% groups
      )
    
  }
  
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
    obs$p_is_outlier > outlier_p_thresh
  
  p <- ggplot2::ggplot(
    spawn_curves,
    ggplot2::aes(
      x = day,
      y = fish,
      colour = group,
      fill = group
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
        colour = group,
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
  
  if (facet == "year") {
    
    p <- p +
      ggplot2::facet_wrap(
        ~year,
        scales = "free_y"
      )
    
  } else {
    
    p <- p +
      ggplot2::facet_grid(
        group ~ year,
        scales = "free_y"
      ) +
      ggplot2::guides(
        colour = "none",
        fill = "none"
      )
    
  }
  
  p <- p +
    ggplot2::theme_bw() +
    ggplot2::theme(
      strip.background =
        ggplot2::element_blank(),
      panel.grid.minor =
        ggplot2::element_blank()
    )
  
  if (y_scale == "none") {
    
    p <- p +
      ggplot2::scale_y_continuous(
        labels = scales::label_number(
          scale_cut = scales::cut_short_scale()
        ),
        name = "Spawners present"
      )
    
  } else {
    
    p <- p +
      ggplot2::scale_y_log10(
        labels = scales::label_number(
          scale_cut = scales::cut_short_scale()
        ),
        name = "Spawners present"
      )
    
  }
  
  month_starts <- seq(
    from = as.Date(
      format(
        min(as.Date(spawn_curves$day,
                    origin = "2023-12-31")),
        "%Y-%m-01"
      )
    ),
    to = as.Date(
      format(
        max(as.Date(spawn_curves$day,
                    origin = "2023-12-31")),
        "%Y-%m-01"
      )
    ),
    by = "month"
  )
  
  p +
    ggplot2::scale_x_continuous(
      breaks = as.numeric(
        month_starts -
          as.Date("2023-12-31")
      ),
      labels = format(
        month_starts,
        "%b"
      ),
      name = NULL
    )
  
}