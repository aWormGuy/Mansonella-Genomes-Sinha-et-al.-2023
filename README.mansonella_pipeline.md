# Pipeline description and scripts used in Mansonella perstans and Mansonella ozzardi genome project (Sinha et al. 2023)

- The scripts described here were run on a SGE / Grid Engine via qsub. 
- All required software was installed using conda under various environments.

## Authors:
- Amit Sinha (New England Biolabs, Ipswich, MA, US)

 
## PacBio assembly for Mpe-Cam-1

#### Step 1: Consensus reads from raw PacBio reads
- Run the protocol `RS_PreAssembler.1`, parameters `minLen=1000, minQual=0.80, genomeSize=100000000` on PacBio SMRT Portal.

#### Step 2: Remove host (human) reads
- Map the consensus reads to the human genome (grch38) using minimap2 v2.17-r941. Use samtools to remove reads that map to the human genome.
- Assemble the remaining reads canu v2.2 (Koren et al., 2017) with parameters `genomeSize=90m correctedErrorRate=0.045` 
- Script : `job-canu-pacbio.sh`


#### Step 3: Assembly polishing using PacBio data only
- The assembly was iteratively polished over 12 rounds using `Resequencing` protocol on PacBio SMRT Portal, parameters `--minMatch 12 --bestn 10 --minPctSimilarity 70.0 --refineConcordantAlignments` till no new variants could be detected by the Resequencing pipeline. 

#### Step 4: Assembly improvement using finisherSC
- The assembly contiguity was further improved by using finisherSC software v2.1 (Lam et al., 2015), a scaffolder that uses raw PacBio reads while accounting for any genomic repeats in the assembly. 
- Script(s) used : `job-finisherSC.sh`

#### Step 5: Polish PacBio assembly using Illumina data
- The assembly was polished using the Illumina data from the same isolate via the polca software.
- Script: `job-polca.sh`

#### Step 6: Gap-filling and heterozygosity removal 
- Use the polished assembly and Illumina reads as an input to the Redundans pipeline v0.14a. 
- Script: `job-redundans.sh`

#### Step 7: Blobplot analysis for binning assembled contigs by taxa of origin : Mansonella, Wolbachia, human, Others...
- See scripts used for Illumina-only assemblies below.
- Blobplot analysis showed that the PacBio assembly was free of non-Mansnella sequences.


## Illumina assemblies for Mpe-Cam-2, Moz-Brazil-1, Moz-Venz-1

### Task 1: Preprocessing of raw reads
##### Key goals
- "Clumpify" : remove optical duplicates
- Removed bad tiles (e.g. in NextSeq data)
- Trim adapters
- Remove phiX sequences
- Remove stretches of poly-G (poly-C on read2) which are an artefact of NextSeq and similar platforms
- Remove reads from the human host
- Run FatsQC 

#### Script(s) used :
- `job00.preprocess-NextSeq-reads.sh`

### Task 2: Metagenomic assembly using metaSpades
### Key goals
- Assemble all nematode and potential Wolbachia contigs

### Script(s) used :
- `job01.metaspades.sh`

### Task 3: Blobplot analysis for binning assembled contigs by taxa of origin : Mansonella, Wolbachia, human, Others...
### Script(s) used : 
- `job02.reads-to-assembly.sh`
- `job03.blastn-assembly.sh`
- `job04.diamond-assembly.sh`
- `job05.create-blobplot.sh`
- `job06.R.blobplot-analysis.R` : This analysis can be run on local computer in RStudio, to explore coverage and %gc cut-offs that will best separated the contigs into correct taxonomic bins. This analysis needs to be customized for each isolate.

### Task 4: Redundans analysis for scaffolding, gap-filling and heterozygosity removal 
### Script(s) used : 
- `job07.redundans.sh`

#### Task 5: Repeat Modeling and Masking
- Identify repeat elements in across all assemblies
- Combine all assemblies into one: `cat Mpe-Cam1.redundans.fasta Mpe-Cam2.redundans.fasta Moz-Brazil1.redundans.fasta Moz-Venz1.redundans.fasta > Mansonella.4assemblies.fasta`
- Run the script `job08.RepeatModeler.sh`. Use the output `RMdb.Mansonella.4assemblies.fa` as the database for RepeatMasker in the next step.
- Run the script `job09.RepeatMasket.sh`on each assembly. Make sure to turn the `softmasking` option on.

#### Task 6: Gene predictions using BRAKER2 pipeline
- Combine the softmasked genome assemblies from each isolate into one fasta file and use it for gene-prediction. This will ensure maximum possible consistency in the same BRAKER2 training parameters are used for annotating genes on each contig of each assembly.
- Script `job10.braker2.sh`
- Separate the gene-predictions for each isolate by parsing the `.gtf` file produced by braker2.
- Script to use : `perl.separate-braker-genes.pl`

## Comparative genomic analysis

#### 1. Jupiter  plots for genome-wide similarity and synteny
- Script: `job11.jupiter-plot.sh`
- Import the svg file into Adobe Illustrator for editing.

#### 2. NucDiff analysis to study genetic variation across isolates and species
- Script: `job12.nucdiff-run.sh`
- Parse the NucDiff output to count local variants (SNVs, small insertions and deletions) in genomic subregions namely: (1) inside gene body (2) outside gene bodies (3) within introns (4) within exons
- Use the VCF file produced by NucDiff as an input to snpEff on Galaxy server.

#### 3. BUSCO Analysis
- Collect proteomes of all relevant nematode species in a single folder (See Supplementray Table 1 of the manuscript for data sources)
- Script : `job13.busco-on-proteomes.pl
- Compile busco results into a single tsv file and plot together using the R script `r.busco-plot.R`

#### 4. OrthoFinder Analysis
- For each nematode being analyzed, select the longest transcript isoform for each gene. 
- Usually gene annotations are from braker / augustus and multiple transcripts of a gene e.g. `g1` are named as `g1.t1`, `g1.t2` and so on.
- Scripts: 

#### 5. Phylogenomic analysis for nematodes

#### 6. Identification and annotation of mitochondria to nuclear transfer (nuMTs)

#### 7. Identification and annotation of Wolbachia to nuclear transfer (nuWTs)

### 8. Phylogenetic analysis of known drug targets




******
## License
Licensed as GNU General Public License v3.0. See LICENSE file in the root directory of this source tree.
[![License](https://img.shields.io/github/license/aWormGuy/Mansonella-Genomes-Sinha-et-al.-2023)](https://opensource.org/license/gpl-3-0/)


