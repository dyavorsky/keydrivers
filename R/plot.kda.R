# Helper: reshape importance matrix (+ optional CIs) to long format for plotting
.kda_long <- function(importance, ci_lower = NULL, ci_upper = NULL) {
  nr <- nrow(importance)
  nc <- ncol(importance)

  df <- data.frame(
    driver     = rep(rownames(importance), times = nc),
    method     = rep(colnames(importance), each  = nr),
    importance = as.vector(importance),
    stringsAsFactors = FALSE
  )

  if (!is.null(ci_lower) && !is.null(ci_upper)) {
    df$ci_lower <- as.vector(ci_lower)
    df$ci_upper <- as.vector(ci_upper)
  }

  df <- df[!is.na(df$importance), ]

  # Order drivers by mean importance; ascending factor levels so largest plots at top
  means     <- tapply(df$importance, df$driver, mean, na.rm = TRUE)
  df$driver <- factor(df$driver, levels = names(sort(means)))

  df
}


# Helper: apply shared theme and optional color/background customisation
.kda_theme <- function(p, colors, bg_color) {
  p <- p +
    theme_minimal() +
    theme(
      panel.background  = element_rect(fill = bg_color, color = NA),
      plot.background   = element_rect(fill = bg_color, color = NA),
      panel.grid.major.y = element_line(linetype = "dashed", color = "grey80"),
      panel.grid.minor   = element_blank(),
      legend.position    = "right"
    )
  if (!is.null(colors))
    p <- p + scale_color_manual(values = colors)
  p
}


#' @param x A \code{kda} object returned by \code{\link{kda}}.
#' @param y Ignored; present for S3 compatibility.
#' @param colors Optional character vector of colors for each method. Can be
#'   named (matched to method names) or unnamed (applied in order). If
#'   \code{NULL} (default), the ggplot2 default palette is used.
#' @param bg_color Background color for the plot panel and overall plot area
#'   (default \code{"white"}).
#' @param ... Ignored.
plot.kda <- function(x, y = NULL, colors = NULL, bg_color = "white", ...) {
  df <- .kda_long(x$importance)
  x_label <- if (isTRUE(x$normalize)) "Importance Score (% of total)" else "Importance Score"

  p <- ggplot(df, aes(x = importance, y = driver, color = method)) +
    geom_point(position = position_dodge(width = 0.5), size = 2.5) +
    labs(x = x_label, y = NULL, color = "Method")

  .kda_theme(p, colors, bg_color)
}


#' @param x A \code{kda_boot} object returned by \code{\link{kda_boot}}.
#' @param y Ignored; present for S3 compatibility.
#' @param colors Optional character vector of colors for each method.
#' @param bg_color Background color (default \code{"white"}).
#' @param ... Ignored.
plot.kda_boot <- function(x, y = NULL, colors = NULL, bg_color = "white", ...) {
  df <- .kda_long(x$estimate$importance, x$ci_lower, x$ci_upper)
  x_label <- if (isTRUE(x$estimate$normalize)) "Importance Score (% of total)" else "Importance Score"

  p <- ggplot(df, aes(x = importance, y = driver, color = method)) +
    geom_errorbarh(aes(xmin = ci_lower, xmax = ci_upper),
                   position = position_dodge(width = 0.5),
                   height = 0, linewidth = 0.5) +
    geom_point(position = position_dodge(width = 0.5), size = 2.5) +
    labs(x = x_label, y = NULL, color = "Method")

  .kda_theme(p, colors, bg_color)
}
