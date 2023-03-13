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

NUMCPU=8;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU
ASSEMBLY="metagenome_mpe_Cam1";
PREFIX="blob_metagenome_mpe_Cam1"
OUT_BLASTN=$PREFIX".blastn";
OUT_DMND=$PREFIX".diamond";

NCBI_NT_DB=$CORE_DATA"/ncbi/ncbi_nt_20200427/nt";
#UNIPROT_BLOBTOOLS_DMND="";


echo;echo "######################################################";
CMD="blastn -query $ASSEMBLY -db $NCBI_NT_DB -num_threads $NUM_THREADS -outfmt '6 qseqid staxids bitscore std' -max_target_seqs 10 -max_hsps 1 -evalue 1e-25 > $OUT_BLASTN";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

#CMD="diamond blastx --query $ASSEMBLY --db $UNIPROT_BLOBTOOLS_DMND --outfmt 6 --sensitive --max-target-seqs 1 --evalue 1e-25 > $OUT_DMND";
#echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################

