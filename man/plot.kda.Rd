\name{plot.kda}
\alias{plot.kda}
\alias{plot.kda_boot}

\title{Plot Key Drivers Analysis Results}

\description{
S3 plot methods for objects returned by \code{\link{kda}} and
\code{\link{kda_boot}}. Produces a horizontal dot plot with one row-group per
key driver variable (ordered from most to least important) and one colored
point per enabled method. For \code{kda_boot} objects, bootstrap confidence
intervals are drawn as horizontal lines behind each point.
}

\usage{
\method{plot}{kda}(x, y = NULL, colors = NULL, bg_color = "white", ...)

\method{plot}{kda_boot}(x, y = NULL, colors = NULL, bg_color = "white", ...)
}

\arguments{
\item{x}{A \code{kda} or \code{kda_boot} object.}

\item{y}{Ignored; present for S3 compatibility.}

\item{colors}{Optional character vector of colors for the method points and CI
  lines. May be named (matched by method name) or unnamed (applied in the
  order methods appear). When \code{NULL} (default), the ggplot2 default
  discrete palette is used.}

\item{bg_color}{Background color for the plot panel and overall plot area.
  Any color string accepted by R (default \code{"white"}).}

\item{...}{Ignored.}
}

\details{
Driver variables are ordered on the vertical axis by their mean normalized
importance score across all enabled methods, with the most important driver
at the top.

\code{NA} importance scores (e.g., Johnson Relative Weights for ordinal
outcomes) are silently dropped and that method's point is omitted for the
affected driver.

The returned object is a \code{ggplot} and can be further modified with
standard ggplot2 layers and theme adjustments.
}

\value{
A \code{ggplot} object.
}

\seealso{
\code{\link{kda}}, \code{\link{kda_boot}}
}

\examples{
data(mtcars)

# Basic plot — point estimates only
result <- kda(mpg ~ disp + hp + wt + drat, data = mtcars,
              corr = TRUE, beta = TRUE, shapley = TRUE, verbose = FALSE)
plot(result)

# Custom colors and background
plot(result,
     colors   = c(correlation = "steelblue", beta = "tomato", shapley = "goldenrod"),
     bg_color = "#f5f5f5")

# Bootstrap plot — points with confidence intervals
result_boot <- kda_boot(mpg ~ disp + hp + wt + drat, data = mtcars,
                        B = 100, seed = 42,
                        corr = TRUE, beta = TRUE, randforest = TRUE)
plot(result_boot)

# Save with ggsave
\dontrun{
p <- plot(result_boot)
ggplot2::ggsave("key_drivers.png", p, width = 8, height = 5)
}
}

\author{Dan Yavorsky}
