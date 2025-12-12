# This script benchmarks a sample VCF against GIAB HG002 using Truvari,
# normalizes VCFs, cleans BED files, and uploads results to GCS.

#!/usr/bin/env bash
set -euo pipefail

#set working directory to TERRA 
WD= "Insert working directory here"
#Use Genome in a Bottle (GIAB) HG002 benchmark VCF for GRCh38
REF="GCA_000001405.15_GRCh38_no_alt_analysis_set.fna"
GIAB_VCF="HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.broad-header.vcf.gz"
GIAB_NORM_VCF="HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.norm.vcf.gz"
GIAB_NORM_VCF2="HG002_GRCh38_GIAB_1_22_v4.2.1_benchmark.norm_GRCh38noalt.vcf.gz"  #main chromosome with alternate locis

#Sample Variant Call Format file
SAMPLE_VCF="normNA24385_NA24385_O1D1_SM-G947H_v1.hard-filtered.vcf.gz" 
SAMPLE_MAIN_VCF="sample.main.vcf.gz" 
SAMPLE_NORM_VCF="normNA24385.final.vcf.gz"

#Sample BED file 
BED_ORIG="GCA_000001405.15_GRCh38_GRC_exclusions.bed"
BED_CLEAN="GCA_000001405.15_GRCh38_GRC_exclusions.clean.bed"

# Set google cloud working directory
GCS_DIR= "gs://fc-38e557b0-ad7b-436d-a03a-2aca9c52c055/DRAGEN_run_folders/HG002/hard-polyg-3-5prime-adapter/NA24385_NA24385_O1D1_SM-G947H_v1/"

cd "$WD"
echo "Working directory: $WD"

# 1. Index the reference FASTA (faidx) and create sequence dictionary
echo "Indexing reference (faidx)..."
samtools faidx "$REF"

# Create sequence dictionary with GATK
echo "Creating sequence dictionary with GATK..."
gatk CreateSequenceDictionary -R "$REF" -O "${REF%.*}.dict" 

# 2. Fix GIAB VCF header SVLEN Number 
echo "Checking GIAB VCF header for SVLEN Number..."
if bcftools view -h "$GIAB_VCF" | grep -q "ID=SVLEN,Number="; then
  echo "Modifying SVLEN header to Number=A (if needed) and reheadering..."
  bcftools view -h "$GIAB_VCF" \
    | sed 's/ID=SVLEN,Number=[^,]*/ID=SVLEN,Number=A/' \
    | bcftools reheader -h /dev/stdin -o "${GIAB_VCF%.vcf.gz}.reheader.vcf.gz" "$GIAB_VCF"
  GIAB_VCF_REHEADER="${GIAB_VCF%.vcf.gz}.reheader.vcf.gz"
  GIAB_VCF="$GIAB_VCF_REHEADER
"
  echo "Reheadered GIAB VCF -> $GIAB_VCF"
else
  echo "SVLEN header exist."
fi

# 3. Normalize the GIAB VCF against the no-alt reference
echo "Normalizing GIAB VCF against $REF..."
# Use --check-ref x to auto-correct potential REF mismatches (safe because we use official reference)
bcftools norm -f "$REF" -m -any --check-ref x "$GIAB_VCF" -Oz -o "$GIAB_NORM_VCF"
bcftools index "$GIAB_NORM_VCF"
echo "GIAB normalization complete and indexed: $GIAB_NORM_VCF"

# bcftools norm -c s to report mismatches 
echo "Checking for REF mismatches (should be none) ..."
bcftools norm -f "$REF" "$GIAB_NORM_VCF" -c s || true

# 4. Clean the BED file: remove browser/track/# lines and empty lines, keep first 3 columns
echo "Cleaning BED file (remove headers and keep chrom,start,end)..."
grep -vE '^(#|browser|track)' "$BED_ORIG" \
  | awk 'NF>=3 {print $1"\t"$2"\t"$3}' > "$BED_CLEAN"
# make sure no CRLF
sed -i.bak 's/\r$//' "$BED_CLEAN" || true
echo "Clean BED written to: $BED_CLEAN"
echo "BED preview:"
head -n 10 "$BED_CLEAN" || true

# 5. Upload cleaned BED and GIAB normalized VCF + index to GCS (optional)
echo "Uploading GIAB normalized VCF, index, and cleaned BED to GCS..."
gsutil cp "$GIAB_NORM_VCF" "$GCS_DIR"
# upload index (csi or tbi)
if [[ -f "${GIAB_NORM_VCF}.csi" ]]; then
  gsutil cp "${GIAB_NORM_VCF}.csi" "$GCS_DIR"
elif [[ -f "${GIAB_NORM_VCF}.tbi" ]]; then
  gsutil cp "${GIAB_NORM_VCF}.tbi" "$GCS_DIR"
fi
gsutil cp "$BED_CLEAN" "$GCS_DIR"
echo "Upload complete."

# 6. Filter sample VCF to main chromosomes only (remove alt contigs)
echo "Filtering sample VCF to main chromosomes (remove ALT contigs)..."
bcftools view -r chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY,chrM \
  -Oz -o "$SAMPLE_MAIN_VCF" "$SAMPLE_VCF"
bcftools index "$SAMPLE_MAIN_VCF"
echo "Sample main-chrom VCF created and indexed: $SAMPLE_MAIN_VCF"

# 7. Normalize the sample VCF against the same no-alt reference
echo "Normalizing sample VCF against $REF..."
# If there are REF mismatches, allow bcftools to fix them (--check-ref x)
bcftools norm -f "$REF" -m -any --check-ref x "$SAMPLE_MAIN_VCF" -Oz -o "${SAMPLE_NORM_VCF}"
bcftools index "${SAMPLE_NORM_VCF}"
echo "Sample normalization complete and indexed: ${SAMPLE_NORM_VCF}"

# 8. Re-index both files 
echo "Re-indexing normalized VCFs to ensure index timestamps are up-to-date..."
bcftools index -f "$GIAB_NORM_VCF"
bcftools index -f "${SAMPLE_NORM_VCF}"

# 9. Run Truvari benchmark, comparing sample VCF to benchmark VCF
#identifying true positives (TP), false positives (FP), false negatives (FN) and genptype mismatch
#output summary tables, VCFs and stats 
TRUVARI_OUT="truvari_output"
echo "Running Truvari bench..."
truvari bench \
  -b "$GIAB_NORM_VCF" \
  -c "${SAMPLE_NORM_VCF}" \
  --dup-to-ins \
  --pctseq 0 \
  --refdist 2000 \
  --chunksize 2000 \
  --pctsize 0.7 \
  --pctovl 0.0 \
  --passonly \
  --sizemin 50 \
  --sizefilt 35 \
  --sizemax 500000000 \
  --no-ref=c \
  --pick=ac \
  --extend=0 \
  --includebed "$BED_CLEAN" \
  -o "$TRUVARI_OUT"

echo "Truvari finished. Results in: $TRUVARI_OUT"

echo "Pipeline complete."
