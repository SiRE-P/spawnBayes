#' Plot imported NuSEDS survey data
#'
#' Plot raw survey observations imported from NuSEDS.
#'
#' This function is intended as a quick quality-control step
#' before fitting a spawnBayes model. Survey counts are plotted
#' through time and coloured by reach.
#'
#' Inspection-level imports typically produce one reach per
#' stream, while segment-level imports typically produce one
#' reach per NuSEDS segment.
#'
#' @param data A data frame produced by [read_nuseds()].
#' @param y_scale Scale used for the y-axis. One of
#'   `"none"` or `"log10"`.
#'
#' @return A ggplot object showing survey observations by year.
#'
#' @export
plot_nuseds <- function(
    data,
    y_scale = c("none", "log10")
) {
  
  y_scale <- match.arg(y_scale)
  
  required_cols <- c(
    "date",
    "reach",
    "spawner_counts"
  )
  
  missing_cols <- setdiff(
    required_cols,
    names(data)
  )
  
  if (length(missing_cols) > 0)
    stop(
      paste0(
        "Missing required column(s): ",
        paste(missing_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  
  dat <- data |>
    dplyr::mutate(
      year = lubridate::year(date),
      day = lubridate::yday(date)
    )
  
  p <- ggplot2::ggplot(
    dat,
    ggplot2::aes(
      x = day,
      y = spawner_counts,
      colour = reach,
      group = interaction(reach, year)
    )
  ) +
    ggplot2::geom_line(
      linewidth = 0.7,
      alpha = 0.8
    ) +
    ggplot2::geom_point(
      size = 2
    ) +
    ggplot2::facet_wrap(
      ~ year,
      scales = "free_y"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      strip.background =
        ggplot2::element_blank(),
      panel.grid.minor =
        ggplot2::element_blank()
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Spawner count",
      colour = "Reach"
    )
  
  if (y_scale == "none") {
    
    p <- p +
      ggplot2::scale_y_continuous(
        labels = scales::label_number(
          scale_cut = scales::cut_short_scale()
        )
      )
    
  } else {
    
    p <- p +
      ggplot2::scale_y_log10(
        labels = scales::label_number(
          scale_cut = scales::cut_short_scale()
        )
      )
    
  }
  
  p +
    ggplot2::scale_x_continuous(
      labels = function(x)
        format(
          as.Date(
            x,
            origin = "2023-12-31"
          ),
          "%b"
        )
    )
  
}