#' Identify reach-years with potentially multimodal run timing
#'
#' @keywords internal
identify_multimodal_years <- function(data) {
  
  data |>
    dplyr::mutate(year = lubridate::year(date)) |>
    dplyr::group_by(reach, year) |>
    dplyr::group_modify(~{
      
      if (nrow(.x) < 5)
        return(
          data.frame(
            n_major_peaks = 1
          )
        )
      
      sm <- stats::smooth.spline(
        lubridate::yday(.x$date),
        .x$spawner_counts
      )
      
      pred <- predict(
        sm,
        seq(
          min(lubridate::yday(.x$date)),
          max(lubridate::yday(.x$date)),
          by = 1
        )
      )$y
      
      peak_ind <- which(
        diff(sign(diff(pred))) < 0
      ) + 1
      
      if (length(peak_ind) > 1) {
        
        peak_heights <- pred[peak_ind]
        
        major_peaks <- peak_ind[
          peak_heights >
            0.5 * max(peak_heights)
        ]
        
        peak_days <- seq(
          min(lubridate::yday(.x$date)),
          max(lubridate::yday(.x$date)),
          by = 1
        )[major_peaks]
        
        n_major_peaks <- 1
        
        if (length(peak_days) > 1) {
          
          peak_sep <- diff(
            sort(peak_days)
          )
          
          n_major_peaks <-
            1 + sum(peak_sep >= 10)
          
        }
        
      } else {
        
        n_major_peaks <- 1
        
      }
      
      data.frame(
        n_major_peaks = n_major_peaks
      )
      
    }) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      multimodal = n_major_peaks > 1
    ) |>
    dplyr::arrange(reach, year)
  
}