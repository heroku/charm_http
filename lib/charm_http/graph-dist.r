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

# Set up plot
png(outputfile, width=8, height=6, units = 'in', res=150)
# colors = rainbow(nservices)

# Add bars
bar_chart <- ggplot(data, aes(x=buckets, y=percent), colour="blue") +
  geom_bar() +
  xlab("Response Time (ms)") +
  ylab("Percent") +
  scale_y_continuous(labels = percent_format(), limits=c(0,1))

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
