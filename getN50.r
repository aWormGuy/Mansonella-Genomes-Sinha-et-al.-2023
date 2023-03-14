###############
getN50 <- function(lengthsArray) {
	revSorted <- rev(sort(lengthsArray))
	n50_to_return <- revSorted[cumsum(revSorted) >= sum(revSorted)/2][1]
	return(n50_to_return)
} 
##############