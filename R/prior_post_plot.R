#' Plot prior and posterior distributions
#'
#' Compare prior and posterior distributions for key
#' spawnBayes hyperparameters.
#'
#' @param fit A fitted spawnBayes model.
#'
#' @return A ggplot object.
#'
#' @export
prior_post_plot <- function(fit) {
  
  if (!inherits(fit, "spawnBayes_fit"))
    stop("fit must be a spawnBayes_fit object.", call. = FALSE)
  
  priors <- fit$priors
  
  n <- nrow(
    fit$fit$draws(
      "live_phi",
      format = "matrix"
    )
  )
  
  offset <- fit$stan_inputs$day_stand
  
  prior_dat <- dplyr::bind_rows(
    
    data.frame(
      parameter = "Peak arrival",
      value = rnorm(
        n,
        priors$arrival_peak$mean,
        priors$arrival_peak$sd
      ),
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Arrival spread",
      value = exp(
        rnorm(
          n,
          priors$spread$mean,
          priors$spread$sd
        )
      ) + 1,
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Exit lag",
      value = exp(
        rnorm(
          n,
          priors$exit_lag$mean,
          priors$exit_lag$sd
        )
      ) + 1,
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Exit spread",
      value = exp(
        rnorm(
          n,
          priors$spread$mean,
          priors$spread$sd
        )
      ) + 1,
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Arrival SD",
      value = rlnorm(
        n,
        log(priors$arrival_sigma$mean),
        priors$arrival_sigma$sd
      ),
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Arrival-spread SD",
      value = rlnorm(
        n,
        log(priors$spread_sigma$mean),
        priors$spread_sigma$sd
      ),
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Exit-lag SD",
      value = rlnorm(
        n,
        log(priors$spread_sigma$mean),
        priors$spread_sigma$sd
      ),
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Exit-spread SD",
      value = rlnorm(
        n,
        log(priors$spread_sigma$mean),
        priors$spread_sigma$sd
      ),
      distribution = "Prior"
    ),
    
    data.frame(
      parameter = "Count dispersion",
      value = exp(
        rnorm(
          n,
          priors$count_dispersion$mean,
          priors$count_dispersion$sd
        )
      ),
      distribution = "Prior"
    )
    
  )
  
  post_dat <- dplyr::bind_rows(
    
    data.frame(
      parameter = "Peak arrival",
      value = as.vector(
        fit$fit$draws(
          "timing_mu[1]",
          format = "matrix"
        )
      ) + offset,
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Arrival spread",
      value = exp(
        as.vector(
          fit$fit$draws(
            "timing_mu[2]",
            format = "matrix"
          )
        )
      ) + 1,
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Exit lag",
      value = exp(
        as.vector(
          fit$fit$draws(
            "timing_mu[3]",
            format = "matrix"
          )
        )
      ) + 1,
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Exit spread",
      value = exp(
        as.vector(
          fit$fit$draws(
            "timing_mu[4]",
            format = "matrix"
          )
        )
      ) + 1,
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Arrival SD",
      value = as.vector(
        fit$fit$draws(
          "timing_sigma_year[1]",
          format = "matrix"
        )
      ),
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Arrival-spread SD",
      value = as.vector(
        fit$fit$draws(
          "timing_sigma_year[2]",
          format = "matrix"
        )
      ),
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Exit-lag SD",
      value = as.vector(
        fit$fit$draws(
          "timing_sigma_year[3]",
          format = "matrix"
        )
      ),
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Exit-spread SD",
      value = as.vector(
        fit$fit$draws(
          "timing_sigma_year[4]",
          format = "matrix"
        )
      ),
      distribution = "Posterior"
    ),
    
    data.frame(
      parameter = "Count dispersion",
      value = as.vector(
        fit$fit$draws(
          "live_phi",
          format = "matrix"
        )
      ),
      distribution = "Posterior"
    )
    
  )
  
  dat <- dplyr::bind_rows(
    prior_dat,
    post_dat
  )
  
  ggplot2::ggplot(
    dat,
    ggplot2::aes(
      x = value,
      fill = distribution,
      colour = distribution
    )
  ) +
    ggplot2::geom_density(
      alpha = 0.2,
      linewidth = 0.8
    ) +
    ggplot2::facet_wrap(
      ~parameter,
      scales = "free",
      ncol = 3
    ) +
    ggplot2::theme_bw() +
    ggplot2::labs(
      x = NULL,
      y = "Density",
      fill = NULL,
      colour = NULL
    )
}