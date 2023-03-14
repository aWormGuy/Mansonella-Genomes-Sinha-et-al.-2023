# r.blobplot.R

rm(list = ls())

library(ggplot2)
library(tidyverse)
library(reshape2)
library(ggrepel)
library(rgl) # for 3D plots

library(beeswarm)
library(ggbeeswarm)
library(RColorBrewer)

#################################################################
##### Set up colors for diplaying and distinguishing multiple taxa
source("r.setup-blob-colors.R")
pie(rep(1, length(colors18x)), col = colors18x , main="colors18x") # pie showing all colors

### other custom functions required for analysis
source("getN50.r")
source("getSequenceStats_by_Taxa.r")
 

#################################################################
############## Actual analysis ##################################
#################################################################

ASSEMBLY_NAME <- "metagenome_mpe_Cam1";

myblob <- read.table("blob_metagenome_mpe_Cam1.blobDB.bestsum.table.txt", header = F, stringsAsFactors = F)
colnames(myblob) <- c("contig", "length", "gc", "N", "bam0", "phylum_bestBlast", "phylum_s7", "phylum_c8")

myblob$log10Coverage <- log10(myblob$bam0)
myblob$log10Length <- log10(myblob$length)

(	uniqTaxa <- unique(myblob$bestBlast)	)
##  [1] "Nematoda"        "Proteobacteria"  "no-hit"          "undef"           "Platyhelminthes" "Cnidaria"       
##  [7] "Arthropoda"      "Cyanobacteria"   "Mollusca"        "Bacteria-undef"  "Chordata"        "Actinobacteria" 
## [13] "unresolved"      "Viruses-undef"   "Streptophyta"    "Bacteroidetes"  

(	numUniqTaxa <- length(uniqTaxa)	)	#	[1] 16

### Get stats on sequences binned into various taxa bins

myblob_stats <- getSequenceStats_by_Taxa(myblob, "bestBlast")
write.table(myblob_stats, "00.myblob_stats_by_taxa.tsv", sep="\t", col.names = T, row.names = F, quote = F)

###############
## Generating bloboplots

(ymax = ceiling(max(myblob$log10Coverage)) ) # [1] 6
ymax = 5 # To maintain consistency with other blobplots

###############

(gp_all <- ggplot(data = myblob, aes(x = gc, y = log10Coverage, name=contig, length=length)) + 
     geom_point(aes(colour = bestBlast, size = log10(length)), 
     	alpha = 0.4) + 
   		scale_x_continuous(limits= c(0, 1)) + 
		scale_y_continuous(limits= c(0.01, ymax)) + 
		theme_bw() + 
		colScale18x + 
		ggtitle(ASSEMBLY_NAME) + 
		theme(plot.title = element_text(hjust = 0.5))
)

# eyball the plot to figure the log10Coverage cutoff for Mansonella
covCutoff_nematoda = 1.8

(gp_all <- gp_all + geom_hline(yintercept = covCutoff_nematoda, linetype = 2, alpha=0.7)	)

my_pdfname <- paste(ASSEMBLY_NAME,"all-taxa.o1.pdf", sep = ".")
pdf(my_pdfname)
print(gp_all)
dev.off()

###### Creat a Shiny plot : Useful for intercative exploration of blobplots

my_html_name <- paste(ASSEMBLY_NAME,"all-taxa.shiny.html", sep = ".")

( gp_all_ly <- ggplotly(gp_all, tooltip = c("contig", "log10Coverage", "gc", "bestBlast", "length")) )
saveWidget(gp_all_ly, file = my_html_name);
rm(gp_all_ly) # dlete the object to save memory, explor plot in html browser instead of RStudio


###############


(gp_all_o2 <- ggplot(data = myblob, aes(x = bestBlast, y = log10Coverage)) + 
     geom_point(aes(colour = bestBlast, size = log10(length)), 
     	alpha = 0.4) + 
		scale_y_continuous(limits= c(0.01, ymax)) + 
		theme_bw() + 
		geom_hline(yintercept = covCutoff_nematoda, linetype = 2, alpha=0.7) +
		#geom_hline(yintercept = nematoda_covCutoff, linetype = 2, alpha=0.7) +
		colScale18x + 
		theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
		ggtitle(ASSEMBLY_NAME) + 
		theme(plot.title = element_text(hjust = 0.5))
)

my_pdfname <- paste(ASSEMBLY_NAME,"all-taxa.o2.pdf", sep = ".")
pdf(my_pdfname)
print(gp_all_o2)
dev.off()


##########################
# Based on blobplots, decide the cut-offs required for separting Mansonella, Wolbachia and others...

# Collect the following set of contigs as potanetial Mansonella
# (1) All "Nematoda" with cov >= 1.8
# (2) All "Proteobcteria" with cov > 1.8 and GC < 0.5 are also Mansonella

cov_min_cutoff = 1.8
gc_max_cutoff = 0.5
i <- (myblob$log10Coverage > cov_min_cutoff) & (myblob$gc < gc_max_cutoff)
sum(i)	#	[1] 8782
blobs_goodCov <- myblob[i,]

sort(table(blobs_goodCov$bestBlast))
## 
##        Cnidaria        Mollusca      Arthropoda Platyhelminthes        Chordata  Proteobacteria           undef 
##               2               2               3               5              19              73             309 
##        Nematoda          no-hit 
##            2630            3156 

ibin1 <-  blobs_goodCov$bestBlast == "Nematoda"
ibin2 <-  blobs_goodCov$bestBlast == "Proteobacteria"
ibin_1or2 <- ibin1 | ibin2

sum(ibin1)	# [1] 2630
sum(ibin2)	# [1] 73
sum(ibin_1or2)	# [1] 2703


### Add my clusters
myblob$cluster <- NA

myblob[ibin_1or2, "cluster"] <- "Nematoda"

myblob_subset <- myblob[ibin_1or2, ]

(gp <- ggplot(data = myblob_subset, aes(x = gc, y = log10Coverage), fill = NA) + 
     geom_point(aes(colour = phylum_bestBlast, size = log10(length)), 
     	alpha = 0.4, shape=21) + 
   		scale_x_continuous(limits= c(0, 1)) + 
		scale_y_continuous(limits= c(0.01, 5)) +
		geom_hline(yintercept = 1.3, linetype = 2, alpha=0.7)
)

(gp1 <- gp + colScale) # Add my custom colors

pdf("03.Nematoda-Proteobacteria.o1.pdf")
print(gp1)
dev.off()

(	myblob_subset_stats <- getSequenceStats_by_Taxa(myblob_subset, "cluster")	)

## Output nematoda contigs 
my_worm_contigs_file <- paste(ASSEMBLY_NAME, ".mansonella-from-blobs.tsv", sep = "")
write.table(myblob_subset, file = my_worm_contigs_file, sep="\t", row.names=F, col.names=T, quot=F)

########################################################################################





