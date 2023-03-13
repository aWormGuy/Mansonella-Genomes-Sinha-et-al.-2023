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

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=8;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU

IN_FOLDER="finisherSC_on_mpe_Cam1";
MUMMER_PATH="/mnt/home/asinha/miniconda3/envs/mummer4_env/bin";

IN_FASTA="mpe_cam1.polished_reseq.fasta";
IN_SUBREADS="mpe_lib06_pacbio/00.filtered_subreads/job028342/mpe2_filtered_subreads.job028342.fasta";

## finisherSC prefers the genome and pacbio subreads in the same folder. 
## Acheive this by soft-linking
ln -s $IN_FASTA $IN_FOLDER/$IN_FASTA;
ln -s $IN_SUBREADS $IN_FOLDER/$IN_SUBREADS;

conda activate mummer4_env;
CMD="python $SRC/finishingTool-2.1/finisherSC.py -par $NUM_THREADS $IN_FOLDER $MUMMER_PATH";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################

