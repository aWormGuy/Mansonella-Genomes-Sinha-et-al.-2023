#!/bin/env R

library(RColorBrewer)

colors12x <- brewer.pal(12, "Set3")
#colrs12x_idlist <- sapply(colors12x , color.id)

colors18x <- c("firebrick2", "dodgerblue2", "springgreen3", "gray70", "sienna", "tomato1", colors12x)

colr_map <- as.data.frame(uniqTaxa <- unique(myblob$bestBlast))
colnames(colr_map) <- c("Taxa")
colr_map$colr <- NA
# Fixed colors
colr_map[colr_map$Taxa == "Nematoda", "colr"] = "firebrick2"
colr_map[colr_map$Taxa == "Proteobacteria", "colr"] = "dodgerblue2"
colr_map[colr_map$Taxa == "Actinobacteria", "colr"] = "springgreen3"
colr_map[colr_map$Taxa == "no-hit", "colr"] = "gray70"
colr_map[colr_map$Taxa == "undef", "colr"] = "sienna"
colr_map[colr_map$Taxa == "unresolved", "colr"] = "tomato1"
colr_map[colr_map$Taxa == "Chordata", "colr"] = "darkolivegreen2"

# other colors
i <- is.na(colr_map$colr)
(	numNA <- nrow(colr_map[i, ])	) #	[1] 11
colr_map[i, "colr"] = colors12x[1:numNA]

colors18x <- colr_map$colr
names(colors18x) <- colr_map$Taxa
colScale18x <- scale_colour_manual(name = "best_blast_hit",values = colors18x)
