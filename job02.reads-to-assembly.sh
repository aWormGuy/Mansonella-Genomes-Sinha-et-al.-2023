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

set -ue;
echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=16;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU

REF_FASTA="mags_mpe_cam1.fasta";
REF_IDX=$REF_FASTA;

OUT_PREFIX=`basename $REF_FASTA .fasta`;
OUT_PREFIX=$OUT_PREFIX".reads2ssembly";

READS_PE12="mpe_Cam1.libs_combined.step06.human.r1r2.fq.gz";
READS1=$OUT_PREFIX".tmpReads.r1.fq.gz";
READS2=$OUT_PREFIX".tmpReads.r2.fq.gz";


OUT_BAM=$PREFIX".bam";
OUT_FLAGSTAT=$OUT_BAM".flagstat";
OUT_BAM_ALIGNED=$PREFIX".aligned.bam";
OUT_BAM_UNMAPPED=$PREFIX".unaligned.bam";

if [ -f $READS1 ]; then 
	echo "PE reads have already been split from interleaved to two-file format. Skipping re-format.sh";
else
	CMD="reformat.sh in=$READS_PE out1=$READS1 out2=$READS2";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi

conda activate bowtie2_env; 
# 1) create index if needed
index=$REF_FASTA".1.bt2";
if [ -f $index ]; then 
	echo "Bowtie2 index present for $REF_FASTA. Skipping Indexing step";
else
	CMD="bowtie2-build $REF_FASTA $REF_IDX";
	echo;echo "Running: $CMD [`date`]";eval ${CMD};
fi

CMD="bowtie2 --threads $NUMCPU -x $REF_IDX -1 $READS1 -2 $READS2  | samtools view --threads $NUMCPU -bh | samtools sort --threads $NUMCPU -m 4G -o $OUT_BAM";
#CMD="bowtie2 --threads $NUMCPU -x $REF_IDX -U $READS1 | samtools view --threads $NUMCPU -bh | samtools sort --threads $NUMCPU -m 4G -o $OUT_BAM";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="samtools index $OUT_BAM"; # Needed for blobplot
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="samtools flagstat $OUT_BAM > $OUT_FLAGSTAT";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# 3) retain only the mapped/aligned reads; Convert file .sam to .bam
FLAG_UNMAPPED=4;
CMD="samtools view -F $FLAG_UNMAPPED -bh $OUT_BAM | samtools sort --threads $NUMCPU -m 4G -o $OUT_BAM_ALIGNED";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="samtools index $OUT_BAM_ALIGNED";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# 4) Collect the un-mapped reads;
FLAG_UNMAPPED=4;
CMD="samtools view -f $FLAG_UNMAPPED -bh $OUT_BAM | samtools sort --threads $NUMCPU -m 4G -o $OUT_BAM_UNMAPPED";
echo;echo "Running: $CMD [`date`]";eval ${CMD};


CMD="rm -rf $OUT_BAM"; # Delete the huge BAM file to save space
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="rm -rf $READS1 $READS2";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "Step : DONE: `date`";echo;
############### END OF SCRIPT #################################

