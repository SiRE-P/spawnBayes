#' Identify reach-years with potentially multimodal run timing
#'
#' @keywords internal
identify_multimodal_years <- function(data) {
  
  data |>
    dplyr::mutate(
      year = lubridate::year(date)
    ) |>
    dplyr::group_by(
      reach,
      year
    ) |>
    dplyr::group_modify(~{
      
      xday <- lubridate::yday(.x$date)
      
      # Need enough unique survey dates to fit a spline
      if (length(unique(xday)) < 4) {
        
        return(
          data.frame(
            n_major_peaks = 1
          )
        )
        
      }
      
      sm <- try(
        stats::smooth.spline(
          xday,
          .x$spawner_counts
        ),
        silent = TRUE
      )
      
      # If spline fitting fails, assume unimodal
      if (inherits(sm, "try-error")) {
        
        return(
          data.frame(
            n_major_peaks = 1
          )
        )
        
      }
      
      pred_days <- seq(
        min(xday),
        max(xday),
        by = 1
      )
      
      pred <- predict(
        sm,
        pred_days
      )$y
      
      peak_ind <- which(
        diff(sign(diff(pred))) < 0
      ) + 1
      
      if (length(peak_ind) <= 1) {
        
        n_major_peaks <- 1
        
      } else {
        
        peak_heights <- pred[peak_ind]
        
        major_peaks <- peak_ind[
          peak_heights >
            0.5 * max(peak_heights)
        ]
        
        peak_days <- pred_days[
          major_peaks
        ]
        
        if (length(peak_days) <= 1) {
          
          n_major_peaks <- 1
          
        } else {
          
          peak_sep <- diff(
            sort(peak_days)
          )
          
          n_major_peaks <-
            1 + sum(
              peak_sep >= 10
            )
          
        }
        
      }
      
      data.frame(
        n_major_peaks = n_major_peaks
      )
      
    }) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      multimodal = n_major_peaks > 1
    ) |>
    dplyr::arrange(
      reach,
      year
    )
  
}