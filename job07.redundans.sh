#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -pe smp 24 
#$ -l ram=128G 
# To get an e-mail when the job is done:
#$ -m e
#$ -M useremail@server.com
# export all environment variables to SGE
#$ -V

echo "Running scrip $0 on `hostname`"
echo "Job is:"
################################################
cat $0; 
################################################
NUMCPU=24;
NUM_THREADS=48;
MAX_RAM=128; # Max RAM on lcusyer = 376GB as per Tamas

IN_FASTA="mpe_cam2.blobs_done.fasta";
READS_PE12="mpe_Cam2.libs_combined.step06.no_human.r1r2.fq.gz";

OUT_PREFIX="mpe_cam2.redundans";

OUT_DIR="dir_"$OUT_PREFIX;
OUT_LOG=$OUT_PREFIX".log";

READS_PE1=$OUT_PREFIX"inputReads.r1.fq.gz";
READS_PE2=$OUT_PREFIX"inputReads.r2.fq.gz";


#:<<'SKIP'
if [ -f $READS_PE1 ]; then
        echo "PE reads have already been split from interleaved to two-file format. Skipping re-format.sh";
else
	echo;echo "Step 00: Split interleaved reads: `date`";echo;
	CMD="reformat.sh -Xmx64g in=$READS_PE12 out1=$READS_PE1 out2=$READS_PE2";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi
@SKIP

conda activate redundans_py2.7_env;
# Params : Reduction
MIN_IDENTITY=0.90; # 90% for stringency, default = 51%
MIN_OVERLAP=0.90 # 90% for stringency, default = 80%
MIN_CONTIG_LENGTH=500;

# params: Scaffolding
MIN_SCAFF_JOINS=10; # Defaults = 5, min pairs to join contigs
MIN_MAPQ=20; # default value is 10, too loose to avoid HGT mappings

# Params: Gap closing
GAPCLOSE_ITERS=2; # default = 2 rounds
 
echo;echo "Step 01: Begin redundans: `date`";echo;
CMD="$SRC/redundans/redundans.py --verbose -i $READS_PE1 $READS_PE2 --fasta $IN_FASTA --outdir $OUT_DIR --threads $NUM_THREADS  --identity $MIN_IDENTITY --overlap $MIN_OVERLAP --minLength $MIN_CONTIG_LENGTH --joins $MIN_SCAFF_JOINS --mapq $MIN_MAPQ --iters $GAPCLOSE_ITERS --log $OUT_LOG";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

conda deactivate;
echo;echo "DONE: `date`";echo;

############### END OF SCRIPT #################################

