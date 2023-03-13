#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -pe smp 16 
# To get an e-mail when the job is done:
#$ -m e
#$ -M <useremail@server.com>
# export all environment variables to SGE
#$ -V

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=16;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU

IN_GENOME="mpe_Cam1.finisherSC.fasta";

READS_PE12="mpe_Cam1.libs_combined.step06.human.r1r2.fq.gz";

READS_PE1="metagenome_mpe_Cam1.inputReads.r1.fastq";
READS_PE2="metagenome_mpe_Cam1.inputReads.r2.fastq";

OUT_POLISHED="mpe_Cam1.polca.fasta";

if ! [ -f $READS_PE1 ]; then
	echo;echo "Step 00: Split interleaved reads: `date`";echo;
	CMD="reformat.sh -Xmx64g in=$READS_PE12 out1=$READS_PE1 out2=$READS_PE2";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi


conda activate masurca_env;

CMD="polca.sh -a $IN_GENOME -r '$READS1 $READS2' -t $NUM_THREADS -m 2G";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################

