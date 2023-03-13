#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -pe smp 40 
#$ -l ram=376G 
# To get an e-mail when the job is done:
#$ -m e
#$ -M <useremail@server.com>
# Long-running jobs (>30 minutes) should be submitted with:
# #$ -P longrun
# export all environment variables to SGE
#$ -V

echo "Running scrip $0 on `hostname`"
echo "Job is:"
################################################
cat $0; 
################################################
NUMCPU=32;
NUM_THREADS=64;
MAX_RAM=376; # Max RAM on lcusyer = 376GB as per Tamas

READS_PE12="mpe_Cam1.libs_combined.step06.no_human.r1r2.fq.gz";

OUT_PREFIX="metagenome_mpe_Cam1";

READS_PE1=$OUT_PREFIX".inputReads.r1.fq.gz";
READS_PE2=$OUT_PREFIX".inputReads.r2.fq.gz";

OUT_FOLDER="dir_"$OUT_PREFIX;
OUT_FOLDER_QUAST=$OUT_DIR".quast";

OUT_SCAFFOLDS=$OUT_PREFIX".scaffolds.fasta";

if ! [ -f $READS_PE1 ]; then
	echo;echo "Step 00: Split interleaved reads: `date`";echo;
	CMD="reformat.sh -Xmx64g in=$READS_PE12 out1=$READS_PE1 out2=$READS_PE2";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi

CMD="conda activate spades_env";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "Step 01: Begin assembly: `date`";echo;
CMD="metaspades.py --continue -o $OUT_FOLDER";
CMD="metaspades.py --memory $MAX_RAM --threads $NUM_THREADS -1 $READS_PE1 -2 $READS_PE2 -o $OUT_FOLDER";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

SCAFFOLDS_FILE=$OUT_FOLDER/scaffolds.fasta;
if [ -f $SCAFFOLDS_FILE ]; then
	cp $OUT_FOLDER/scaffolds.fasta $OUT_SCAFFOLDS;
	NEW_NAME_PREFIX=$OUT_PREFIX"_NODE";
	sed -i "s/NODE/$NEW_NAME_PREFIX/g" $OUT_SCAFFOLDS; 
	echo "Successfully created SCAFFOLDS_FILE = $SCAFFOLDS_FILE";
	echo "Step 02: QUAST on assembly: `date`";
	quast.py --threads $NUMCPU --scaffolds -o $OUT_FOLDER_QUAST $OUT_SCAFFOLDS;
	#CMD="rm -rf $READS_PE1 $READS_PE2";
	#echo;echo "Running: $CMD [`date`]";eval ${CMD};
else
	#echo; 
	echo "[File $SCAFFOLDS_FILE does not exist. Re-start (meta)sPades assembly]";
	# echo;
fi
echo "DONE: `date`";echo;
############### END OF SCRIPT #################################

