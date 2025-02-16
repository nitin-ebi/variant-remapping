#!/bin/bash

set -Eeuo pipefail

function asserteq() {
  if [[ ! "$1" -eq "$2" ]]
  then
    echo "Assertion Error: $1 not equal to $2"
    exit 1
  fi

}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SOURCE_DIR=$(dirname $SCRIPT_DIR)

# Build the Source VCF
cat << EOT > "${SCRIPT_DIR}/resources/source.vcf"
##fileformat=VCFv4.3
##INFO=<ID=COMMENT,Number=1,Type=String,Description="Comment">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Consensus Genotype across all datasets with called genotype">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
#CHROM	POS	ID	REF	 ALT	QUAL 	FILTER	INFO	FORMAT	HG001
chr1	1	.	CG	TG	50	PASS	.	GT:GQ	1/1:0
chr1	48	.	C	A,T	50	PASS	COMMENT=NANANANANANANANANANANANANAN%ANANANANANANANANANANANANANANANANAN|ANANANANANANA&NANAN ANA\$NANANANANANANANANANANANANANANANANAN^ANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANA NANANANANANANANANANANANANABATMAN	GT:GQ	1/1:0
chr1	98	.	C	CG	50	PASS	.	GT:GQ	1/1:0
chr1	1078	.	G	A	50	PASS	.	GT	1/1
chr1	2030	.	A	TCC	50	PASS	.	GT:GQ	1/1:0
chr1	1818	.	AAC	A	50	PASS	.	GT:GQ	1/1:0
chr1	3510	.	T	C	50	PASS	.	GT:GQ	1/1:0
chr1	3709	.	CA	TA	50	PASS	.	GT:GQ	1/1:0
chr1	3710	.	T	A	50	PASS	.	GT:GQ	1/1:0
EOT

nextflow run ${SOURCE_DIR}/main.nf \
-config ${SCRIPT_DIR}/resources/config.yml \
--oldgenome ${SCRIPT_DIR}/resources/genome.fa \
--newgenome ${SCRIPT_DIR}/resources/new_genome.fa \
--vcffile ${SCRIPT_DIR}/resources/source.vcf \
--outfile ${SCRIPT_DIR}/resources/remap.vcf

# Check the presence of the output file
ls ${SCRIPT_DIR}/resources/remap.vcf \
   ${SCRIPT_DIR}/resources/remap_unmapped.vcf \
   ${SCRIPT_DIR}/resources/remap_counts.yml

# Build the expected VCF
cat << EOT > "${SCRIPT_DIR}/resources/expected_remap.vcf"
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	HG001
chr2	48	.	C	A,T	50	PASS	COMMENT=NANANANANANANANANANANANANAN%ANANANANANANANANANANANANANANANANAN|ANANANANANANA&NANAN ANA\$NANANANANANANANANANANANANANANANANAN^ANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANANA NANANANANANANANANANANANANABATMAN;st=+	GT:GQ	1/1:0
chr2	98	.	C	CG	50	PASS	st=+	GT:GQ	1/1:0
chr2	1078	.	A	G	50	PASS	st=+;rac=G-A	GT	0/0
chr2	1818	.	AAC	A	50	PASS	st=+	GT:GQ	1/1:0
chr2	2030	.	A	TCC	50	PASS	st=+	GT:GQ	1/1:0
chr2	3510	.	T	C	50	PASS	st=+	GT:GQ	1/1:0
EOT

# Compare vs the expected VCF
diff "${SCRIPT_DIR}/resources/expected_remap.vcf" <(grep -v '^##' "${SCRIPT_DIR}/resources/remap.vcf")

asserteq `cat ${SCRIPT_DIR}/resources/remap_counts.yml | grep 'all:' | cut -d ' ' -f 2`  9
asserteq `cat ${SCRIPT_DIR}/resources/remap_counts.yml | grep 'filtered:' | cut -d ' ' -f 2`  2


# Clean up after the test
rm -rf work .nextflow* \
       ${SCRIPT_DIR}/resources/source.vcf \
       ${SCRIPT_DIR}/resources/expected_remap.vcf \
       ${SCRIPT_DIR}/resources/remap.vcf \
       ${SCRIPT_DIR}/resources/remap_counts.yml \
       ${SCRIPT_DIR}/resources/remap_unmapped.vcf \
       ${SCRIPT_DIR}/resources/new_genome.fa.* \
       ${SCRIPT_DIR}/resources/genome.fa.fai
