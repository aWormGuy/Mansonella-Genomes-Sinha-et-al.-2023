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

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################
conda activate blobtools_new_env;

NUMCPU=8;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU
ASSEMBLY="metagenome_mpe_Cam1.fasta";

OUT_BLOB=`basename $ASSEMBLY .fasta`;
OUT_BLOB="blob_"$OUT_BLOB;

OUT_BLASTN=$OUT_BLOB".blastn";
OUT_DMND=$OUT_BLOB".diamond";

BAM=$OUT_BLOB".reads2ssembly.bam";

BAM_NAME=`basename $BAM`;
DEFAULT_COV=$OUT_BLOB"."$BAM_NAME".cov";
OUT_COV=$OUT_BLOB".map2cov.cov";
echo;echo "######################################################";
echo "1. blobtools map2cov: `date`";
if [ -f $OUT_COV ]; then
	echo "map2cov output already exists. Skipping to Step 2: view" 
else
	CMD="$SRC/blobtools/blobtools map2cov -i $ASSEMBLY -b $BAM -o $OUT_BLOB"; 
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
	CMD="mv $DEFAULT_COV $OUT_COV";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi
echo;echo "######################################################";
echo "2. blobtools create: `date`";
COV=$OUT_BLOB".blobDB.json";
CMD="$SRC/blobtools/blobtools create \
 -i $ASSEMBLY \
 --cov $OUT_COV \
 --hitsfile $OUT_BLASTN \
 --hitsfile $OUT_DMND \
 -o $OUT_BLOB";

#CMD="$SRC/blobtools/blobtools create \
# -i $ASSEMBLY \
# --cov $OUT_COV \
# --hitsfile $OUT_BLASTN \
# --taxrule bestsumorder \
# --hitsfile $OUT_DMND \
# --taxrule bestsumorder \
# -o $OUT_BLOB";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "######################################################";
echo "2. blobtools view: `date`";
JSON=$OUT_BLOB".blobDB.json";
CMD="$SRC/blobtools/blobtools view -i $JSON --rank genus"; # (supported ranks: 'species', 'genus', 'family', 'order','phylum', 'superkingdom', 'all') [default: phylum] 
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";
echo "3. blobtools plot: `date`";
CMD="$SRC/blobtools/blobtools plot -i $JSON"; 
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################

