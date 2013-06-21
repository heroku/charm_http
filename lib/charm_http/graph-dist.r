# load scales package
library(scales)

# try to load ggplot2
mod <- try(
  library(ggplot2, "logical.return" = TRUE)
)
# install ggplot2 if loading it failed
if(!mod) {
  ">> INSTALLING ggplot2 PACKAGE"
  install.packages(c("ggplot2"), repos='http://cran.cnr.berkeley.edu')
  library(ggplot2)
}

# Parse args
args <- commandArgs(TRUE)
if(length(args) != 1 || is.na(args[1])) {
  ">> ERROR: Missing output filename"
  q(status=1)
} else {
  outputfile = args[1]
}

# Load data
data = read.table('tmp/data-dist.ssv', header=T, sep=" ")

# Convert count to fraction of total count
total_counts <- sum(data$count)
data$percent <- data$count / total_counts
data$buckets <- with(data, reorder(buckets, order))


# nservices = ncol(data) - 1
# nrows = nrow(data)

# Sort column headers
# data = data[,c(c(1), order(names(data[2:ncol(data)]))+c(1))]
# headers = names(data)

# Get X range
# xrange = range(data[1])

# Get Y range
# ymax = 0
# for (i in 1:nservices) {
#   curmax = max(data[i + 1])
#   if (curmax > ymax) {
#     ymax = curmax
#   }
# }
# yrange = c(0,ymax)

# Set up plot
png(outputfile, width=8, height=6, units = 'in', res=150)
# colors = rainbow(nservices)

# Add bars
bar_chart <- ggplot(data, aes(x=buckets, y=percent), colour="blue") +
  geom_bar() +
  xlab("Response Time (ms)") +
  ylab("Percent") +
  scale_y_continuous(labels = percent_format(), limits=c(0,1))
# bar_chart

fortify_pareto_data <- function(data, xvar, yvar, sort = TRUE)
{
  for(v in c(xvar, yvar))
  {
    if(!(v %in% colnames(data)))
    {
      stop(sQuote(v), " is not a column of the dataset")
    }
  }

  if(sort) {
    o <- order(data[, yvar], decreasing = TRUE)
    data <- data[o, ]
    data[, xvar] <- factor(data[, xvar], levels = data[, xvar])
  }

  data[, yvar] <- as.numeric(data[, yvar])
  data$.cumulative.y <- cumsum(data[, yvar])

  data$.numeric.x <- as.numeric(data[, xvar])
  data
}

fortified_data <- fortify_pareto_data(data, "buckets", "percent", sort=FALSE)

pareto_plot <- bar_chart %+% fortified_data +
    geom_line(aes(.numeric.x, .cumulative.y)) +
    ylab("Cumulative Percentage") +
    scale_y_continuous(labels = percent_format(), limits=c(0,1))
pareto_plot




# Add lines
# if (nrows < 2) {
#   data.mx = as.matrix(data[2:ncol(data)])
#   par(las=3, mar=c(5,5,3,1))
#   barplot(data.mx, yaxp=c(0,ymax,4), beside=T, col=colors, xlab=paste(data[1,1], "dynos"), ylab="Responses per second", border=T, names.arg=rep("", nservices))
# } else {
#   for (i in 1:nservices) {
#     if (nrows < 4) {
#       lines(data[[1]], data[[i + 1]], type="l", lwd=3, lty=1, col=colors[i])
#     } else {
#       data.spl = smooth.spline(data[[1]], data[[i + 1]], spar=0.3)
#       lines(predict(data.spl, seq(xrange[1], xrange[2], by=0.1)), type="l", lwd=3, lty=1, col=colors[i])
#     }
#   }
# }

# Add title and legend
# title(headers[1])
# legend(xrange[1], yrange[2] * 0.95, headers[2:ncol(data)], cex=0.8, col=colors, bg='transparent', fill=colors, border=colors)
