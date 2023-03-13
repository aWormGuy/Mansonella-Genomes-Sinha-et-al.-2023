#!/bin/bash
#
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -pe smp 8

# To get an e-mail when the job is done:
#$ -m e
#$ -M useremail@server.com

#
# Long-running jobs (>30 minutes) should be submitted with:
#$ -P longrun

# export all environment variables to SGE
#$ -V

echo "Running script $0 on `hostname`"
echo "Job is:"
################################################"
cat $0;
echo "pwd = `pwd`";
################################################"

#INPUTS
NUMCPU=8; # Check the '-pe smp' variable above
TRIM_PREFIX="mpe.v4.canu-ccs3x";
#TRIM_DIRECTORY=$TRIM_PREFIX"_dir";
TRIM_DIRECTORY=$TRIM_PREFIX;
GENOME_SIZE="90m";
#FILTERED_SUBREADS="mpe36c_filteredSubreads.reads-wolbachia.fastq.gz";
CCS_READS="mpe36c.v4.ccs3x_job028343.03.non-Human.final-all.fastq.gz";

#OUTPUTS
#CORRECTED_READS=$TRIM_DIRECTORY"/"$TRIM_PREFIX".correctedReads.fasta.gz";
TRIMMED_READS=$TRIM_DIRECTORY"/"$TRIM_PREFIX".trimmedReads.fasta.gz";

# Step 01: Correct the sub-reads
:<<'SKIP_THIS' : The ccs3x step on PacBio smrt portal already returns corected reads
canu -correct java=/mnt/home2/asinha/anaconda3/bin/java useGrid=remote \
  gridEngineMemoryOption="-l mem_free=MEMORY" \
  -p $TRIM_PREFIX -d $TRIM_DIRECTORY \
  genomeSize=$GENOME_SIZE \
  -pacbio-raw $FILTERED_SUBREADS;
#collect stats on the output
seqkit stats $CORRECTED_READS > $TRIM_DIRECTORY"/seqstats_correctedReads.txt";
SKIP_THIS

#step 02: Trim the reads
canu -trim java=/mnt/home2/asinha/anaconda3/bin/java useGrid=remote \
  gridEngineMemoryOption="-l mem_free=MEMORY" \
  -p $TRIM_PREFIX  -d $TRIM_DIRECTORY \
  genomeSize=$GENOME_SIZE \
  -pacbio-corrected $CCS_READS;

#collect stats on the output
seqkit stats $TRIMMED_READS > $TRIM_DIRECTORY"/seqstats_trimmedReads.txt";
echo "ls -lh $TRIMMED_READS";
ls -lh $TRIMMED_READS;
echo "Trimming complete: `date`";

# Step 03: Assembly
echo "Assembly1, Start: `date`";

MAX_ERROR_RATE_ALLOWED=0.015; # for low coverage data = high stringency = lower error rate allowed during overlaps
#ASSEMBLY_PREFIX="mpe.v4.canu-ccs3x.erate0"$MAX_ERROR_RATE_ALLOWED;
ASSEMBLY_PREFIX="mpe.v4.canu-ccs3x.erate015";
ASSEMBLY_DIRECTORY=$ASSEMBLY_PREFIX;
canu -assemble java=/mnt/home2/asinha/anaconda3/bin/java useGrid=remote \
  gridEngineMemoryOption="-l mem_free=MEMORY" \
  -p $ASSEMBLY_PREFIX -d $ASSEMBLY_DIRECTORY \
  genomeSize=$GENOME_SIZE \
  correctedErrorRate=$MAX_ERROR_RATE_ALLOWED \
  -pacbio-corrected $TRIMMED_READS;
echo "Assembly1, Finish: `date`";


echo "Assembly2, Start: `date`";
MAX_ERROR_RATE_ALLOWED=0.045; # Try with ipermitting a highger error rate - Decreases fragmentation???
#ASSEMBLY_PREFIX="mpe.v4.canu-ccs3x.erate0"$MAX_ERROR_RATE_ALLOWED;
ASSEMBLY_PREFIX="mpe.v4.canu-ccs3x.erate045";
ASSEMBLY_DIRECTORY=$ASSEMBLY_PREFIX;
canu -assemble java=/mnt/home2/asinha/anaconda3/bin/java useGrid=remote \
  gridEngineMemoryOption="-l mem_free=MEMORY" \
  -p $ASSEMBLY_PREFIX -d $ASSEMBLY_DIRECTORY \
  genomeSize=$GENOME_SIZE \
  correctedErrorRate=$MAX_ERROR_RATE_ALLOWED \
  -pacbio-corrected $TRIMMED_READS;
echo "Assembly2, Finish: `date`";
echo "DONE: `date`";
############### END OF SCRIPT #################################

