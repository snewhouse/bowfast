#!/bin/bash
#BSUB -J shrimp.map
#BSUB -o logs/%J.shrimp.out
#BSUB -e logs/%J.shrimp.err
#BSUB -R "rusage[mem=35000]"
#BSUB -n 12

##http://compbio.cs.toronto.edu/shrimp/README
mkdir -p logs

export SHRIMP_FOLDER=~/src/shrimp/SHRiMP_2_2_1/
PATH=$PATH:~/src/shrimp/SHRiMP_2_2_1/bin/:~/src/shrimp/SHRiMP_2_2_1/utils

RAM=12
THREADS=12
FASTA=~/data/hg19.fa
CSFASTA=$1
QUALS=$2
PREFIX=$3
##solid2fastq $1 $2 > $PREFIX.bfastq

SPREFIX=$(basename $FASTA .fa).shrimp.cs
##python $SHRIMP_FOLDER/utils/split-db.py --dest-dir $(dirname $FASTA) --ram-size $RAM --prefix $SPREFIX $FASTA
##python $SHRIMP_FOLDER/utils/project-db.py --dest-dir $(dirname $FASTA) \
##    --shrimp-mode cs $(dirname $FASTA)/${SPREFIX}-${RAM}*.fa

i=0
<<DONE
for db in $(dirname $FASTA)/${SPREFIX}-${RAM}*.fa; do
    i=$(($i + 1))
    rm -f logs/${i}.shrimper.out 
    rm -f logs/${i}.shrimper.err
    echo "gmapper-cs --fastq --bfast \
        --un ${PREFIX}.${i}.un -N $THREADS --single-best-mapping \
        ${PREFIX}.bfastq $db \
          > ${PREFIX}.${i}.shrimp.sam" \
         | bsub -J shrimper.${i} -n $THREADS -e logs/${i}.shrimper.err \
                 -o logs/${i}.shrimper.out -R "rusage[mem=15000]"

done
exit;
DONE
mergesam --threads $THREADS \
     --single-best-mapping --sam ${PREFIX}.bfastq ${PREFIX}.*.shrimp.sam \
     | samtools view -bS -F 4 - > ${PREFIX}.unsorted.bam
samtools sort ${PREFIX}.unsorted.bam ${PREFIX}
samtools index ${PREFIX}.bam
