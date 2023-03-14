require(tidyverse)
require(reshape2)

###############
getSequenceStats_by_Taxa <- function(blobData, statsByColumn) {
	i <- colnames(blobData)  == statsByColumn
	useColumn <- colnames(blobData[i])
	taxaList <- list((blobData[,useColumn]))
	
	x1 <- aggregate(blobData$length, FUN=length, by = taxaList)
	colnames(x1) <- c("taxa", "numContigs")
	x2 <- aggregate(blobData$length, FUN=sum, by = taxaList)
	colnames(x2) <- c("taxa", "totalSize")
	x3 <- aggregate(blobData$length, FUN=median, by = taxaList)
	colnames(x3) <- c("taxa", "medianLength")
	x4 <- aggregate(blobData$length, FUN=getN50, by = taxaList)
	colnames(x4) <- c("taxa", "N50_size")
	x5 <- aggregate(blobData$length, FUN=max, by = taxaList)
	colnames(x5) <- c("taxa", "maxLength")
	x6 <- aggregate(blobData$gc, FUN=median, by = taxaList)
	colnames(x6) <- c("taxa", "gc_median")
	x7 <- aggregate(blobData$log10Coverage, FUN=median, by = taxaList)
	colnames(x7) <- c("taxa", "log10coverage_median")

	blobData_stats <- list(x1, x2, x3, x4, x5, x6, x7) %>% reduce(left_join, by = "taxa")
	blobData_stats$totalSize_MB <- (blobData_stats$totalSize / 1e6)
	blobData_stats <- blobData_stats[,c("taxa", "numContigs", "totalSize_MB", "totalSize", "N50_size", "medianLength" , "maxLength", "gc_median", "log10coverage_median")]
	i <- order(blobData_stats$totalSize, decreasing = T)
	return(blobData_stats[i,])
} 
##############
