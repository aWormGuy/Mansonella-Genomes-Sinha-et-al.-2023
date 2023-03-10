#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -pe smp 8
# To get an e-mail when the job is done:
#$ -m e
#$ -M <useremail@server.com>
# export all environment variables to SGE
#$ -V

set -ue;
echo "Running script $0 on `hostname`"
#echo "Job is:"
################################################"
#cat $0;
echo "pwd = `pwd`";
################################################"

NUMCPU=8;	#	Check the '-pe smp' variable above
NUM_THREADS=32;	#	Make max 4X of $NUMCPU

READS1="../01.raw_fastq/mpe_lib01/mpe_lib01.r1.fq.gz";
READS2="../01.raw_fastq/mpe_lib01/mpe_lib01.r2.fq.gz";

PREFIX=`basename $READS1 .r1.fq.gz`;
echo "PREFIX = $PREFIX";

BBMAP_RESOURCES="$DATA/core_data/bbmap_resources";
HUMAN_IDX_BBMAP="$DATA/core_data/bbmap_index_human_masked";
#TMP="tmp00."$PREFIX".r1r2.fq.gz";
#echo "tmp = $TMP";

OUT_STEP00=$PREFIX".step00.clumpified.r1r2.fq.gz";
OUT_STEP01=$PREFIX".step01.filtered_by_tile.fq.gz";
OUT_STEP02=$PREFIX".step02.no-adapters.r1r2.fq.gz";
OUT_STEP03=$PREFIX".step03.no-phiX.r1r2.fq.gz";
OUT_STEP03_PHIX_STATS=$PREFIX".step03.phix-stats.txt";

OUT_STEP04=$PREFIX".step04.no-polyG.r1r2.fq.gz";
OUT_STEP05=$PREFIX".step05.no-polyC.r1r2.fq.gz";

OUT_STEP06_NON_HUMAN=$PREFIX".step06.non-human.r1r2.fq.gz";
OUT_STEP06_HUMAN=$PREFIX".step06.human.r1r2.fq.gz";

OUT_STATS=$PREFIX".stats";
# Based on: https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/data-preprocessing/
# Step 00: Clumpify reads to get rid of PCR/optical duplicates and other NextSeq artifacts. (Change to interleaved format first)
# See clumpify recommendations from Devon Ryan at : https://www.biostars.org/p/277013
## UPDATE : Clumpify instructions : https://www.biostars.org/p/225338/
echo;echo "######################################################";
echo "Step 00: Clumpify NextSeq: `date`";echo;
CMD="clumpify.sh -Xmx56g in1=$READS1 in2=$READS2 out=$OUT_STEP00 dedupe=t optical=t spany adjacent dupesubs=2 qin=33 markduplicates=f optical=t dupedist=40";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 01: Filter-by-Tile.
echo;echo "######################################################";
echo "Step 01: Use filter_by_tile to remove bad quality reads/tiles: `date`";echo;
CMD="filterbytile.sh -Xmx56g in=$OUT_STEP00 out=$OUT_STEP01";
echo;echo "Running: $CMD [`date`]";eval ${CMD};


# Step 02: #AMIT-Adapter-trimming. Always recommended. Tool: BBDuk.
echo;echo "######################################################";
echo "Step 02: Adapter trimming, Quality-based trimming: `date`";echo;
CMD="bbduk.sh -Xmx56g in=$OUT_STEP01 out=$OUT_STEP02 ktrim=r k=23 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/truseq.fa.gz",$BBMAP_RESOURCES"/NEB_adapters_amit.fa.gz" qtrim=r trimq=10 minlength=50 tpe tbo ftm=5";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 03: Contaminant filtering for synthetic molecules and spike-ins such as PhiX. Always recommended. Tool: BBDuk.
echo;echo "######################################################";
echo "Step 03: phiX rmoval: `date`";echo;
CMD="bbduk.sh -Xmx56g in=$OUT_STEP02 out=$OUT_STEP03 k=31 ref=$BBMAP_RESOURCES"/phix174_ill.ref.fa.gz",$BBMAP_RESOURCES"/sequencing_artifacts.fa.gz" stats=$OUT_STEP03_PHIX_STATS minlength=50 ordered cardinality";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "######################################################";
echo "Step 04: poly-G removal: `date`";echo;
CMD="bbduk.sh -Xmx56g in=$OUT_STEP03 out=$OUT_STEP04 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-G.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";
echo "Step 05: poly-C removal: `date`";echo;
CMD="bbduk.sh -Xmx56g in=$OUT_STEP04 out=$OUT_STEP05 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-C.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";

# Step 06: Human host removal. 
echo;echo "######################################################";
echo "Step 06: Human host removal: `date`";echo;
####  To map quickly with very high precision and lower sensitivity, as when removing contaminant reads specific to a genome without risking false-positives: (From https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/bbmap-guide/)
CMD="bbmap.sh -Xmx56g in=$OUT_STEP05 outm=$OUT_STEP06_HUMAN outu=$OUT_STEP06_NON_HUMAN path=$HUMAN_IDX_BBMAP minratio=0.9 maxindel=3 bwr=0.16 bw=12 fast minhits=2 qtrim=r trimq=10 untrim idtag printunmappedcount kfilter=25 maxsites=1 k=14 threads=$NUM_THREADS"; 
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="seqkit stats --threads $NUM_THREADS $PREFIX*.gz --out-file $OUT_STATS";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
#RUN_ONLY_FASTQC

#:<<'SKIP_FASTQC'
echo "Step 01-B: Run fastqc to see effect of filter_by_tile";
CMD="fastqc --nogroup -t $NUM_THREADS $OUT_STEP00";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
CMD="fastqc --nogroup -t $NUM_THREADS $OUT_STEP01";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
#SKIP_FASTQC
BBMAP_VERSION_STR=`conda list |grep bbmap`;
echo "BBMAP_VERSION_STR = $BBMAP_VERSION_STR";
echo "DONE: `date`";
############### END OF SCRIPT #################################


