#!/usr/bin/Rscript

# Author: Fritz Lekschas
# Date: 03.07.2014

# Load and if needed install libraries
if(suppressMessages(!require("optparse"))) {
  print("Trying to install optparse.")
  install.packages("optparse")
  if(require("optparse")){
    print("Optparse installed and loaded.")
  } else {
    stop("Could not install optparse.")
  }
}

if(suppressMessages(!require("pvclust"))) {
  print("Trying to install pvclust")
  install.packages("pvclust")
  if(require("pvclust")){
    print("Pvclust installed and loaded.")
  } else {
    stop("Could not install pvclust")
  }
}

if(suppressMessages(!require("gplots"))) {
  print("Trying to install gplots.")
  install.packages("gplots")
  if(require("gplots")){
    print("Gplots installed and loaded.")
  } else {
    stop("Could not install gplots.")
  }
}

if(suppressMessages(!require("RColorBrewer"))) {
  print("Trying to install RColorBrewer")
  install.packages("RColorBrewer")
  if(require("RColorBrewer")){
    print("RColorBrewer installed and loaded.")
  } else {
    stop("Could not install RColorBrewer")
  }
}

# Define options
option_list <- list(
  make_option(c("-c", "--comma"),
              action="store_true",
              default=FALSE,
              help="Set comma as CSV separator. [default %default]"),
  make_option(c("-o", "--output"),
              type="character",
              default=getwd(),
              help="Output directory. [default %default]"),
  make_option(c("--color"),
              type="character",
              default="Blues",
              help="Heat map colours. [default %default]"),
  make_option(c("--width"),
              type="integer",
              default=800,
              help="Width in pixel for plotting. [default %default]"),
  make_option(c("--height"),
              type="integer",
              default=800,
              help="Height in pixel for plotting. [default %default]")
)

# Define parser
parser = OptionParser(usage = "%prog [options] DSV-FILE", option_list=option_list)

# Parse arguments and options
arguments = parse_args(parser, positional_arguments = 1)
opt = arguments$options
args = arguments$args

# Set DSV separator
if (opt$comma) {
  separator = ","
} else {
  separator = "\t"
}

# # Check if output directory exists when specified
# if (!is.null(opt$output)) {
#   if (file.exists(opt$output)) {
#     outputDir <- opt$output
#   } else {
#     stop("Output directory does not exist.")
#   }
# } else {
#   output <- getwd()
# }

if (file.exists(args[1])) {
  data <- read.table(args[1], header=TRUE, sep=separator, row.names=1)
} else {
  stop("DSV file not found.")
}

res <- tryCatch({
  data.t <- t(data) # transpose HOT_data
  data.t.dist <- dist(data.t) # euclidean distance
  data.euclid.fit <- hclust(data.t.dist)
  euclid_dend <- as.dendrogram(data.euclid.fit) # get ordering for heatmap
  data.pv_fit <- pvclust(data, method.hclust="complete", method.dist="euclidian", n=1000) # in this case no transform is need
  my_colours <- brewer.pal(8,opt$color)
  png(file=paste(opt$output, "/", args[1], "_heatmap.png", sep=""), width=opt$width, height=opt$height, bg="transparent")
  heatmap.2(as.matrix(data), margin=c(10,10), 
                             col=my_colours, 
                             Colv=euclid_dend, 
                             trace="none", 
                             denscol="black")
  
  my_colours <- c("#73e5ac", "#70d3b3", "#ff4119", "#6dc1ba", "#6cb8be", "#6aafc1", "#69a6c5", "#679dc8", "#6694cc")
  
  png(file=paste(opt$output, "/", args[1], "_barplot_abs.png", sep=""), width=opt$width, height=opt$height, bg="transparent")
  par(mfrow=c(1, 1), mar=c(5, 5, 4, 10))
  barplot(as.matrix(dataRel), col=my_colours, main="Absolute dominance of fungi in eukaryotes", legend = rownames(dataRel), xlab="Habitats", ylab="Percentage of reads", args.legend = list(x = "topright", bty = "n", inset=c(-0.325, 0.25)), cex.lab=1.66, cex.axis=1.33, cex.main=2)

  dataRel <- t(t(data)/colSums(data))
  png(file=paste(opt$output, "/", args[1], "_barplot_rel.png", sep=""), width=opt$width, height=opt$height, bg="transparent")
  par(mfrow=c(1, 1), mar=c(5, 5, 4, 10))
  barplot(as.matrix(dataRel), col=my_colours, main="Relative dominance of fungi in eukaryotes", legend = rownames(dataRel), xlab="Habitats", ylab="Percentage of reads", args.legend = list(x = "topright", bty = "n", inset=c(-0.325, 0.25)), cex.lab=1.66, cex.axis=1.33, cex.main=2)
  dev.off()
}, warning = function(w) {
  message(paste("Download GEO Series does not seem to exist:", args[1]))
  message("Here's the original error message:")
  message(w)
  # Choose a return value in case of error
  return(NA)
}, error = function(e) {
  message(paste("Download GEO Series caused a warning:", args[1]))
  message("Here's the original warning message:")
  message(e)
  # Choose a return value in case of warning
  return(NULL)
}, finally = {
  message(paste("Generated a heat map for", args[1]))
})
