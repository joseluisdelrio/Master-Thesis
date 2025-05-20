#!/bin/bash

# Definir directorios basados en la estructura del proyecto
BASE_DIR=".."  # Carpeta base (nivel superior a scripts)
GENOME_DIR="$BASE_DIR/genome/index"  # Ruta al índice del genoma
ANNOTATION_GTF="$BASE_DIR/genome/Mus_musculus.GRCm39.113.gtf"  # Archivo GTF para StringTie
SAMPLES_DIR="$BASE_DIR/samples"  # Directorio donde están las muestras
OUTPUT_DIR="$BASE_DIR/results"  # Directorio donde se guardarán los resultados
QUALITY_DIR="${OUTPUT_DIR}/quality"  # Carpeta para control de calidad
ALIGNMENT_DIR="${OUTPUT_DIR}/alignment"  # Carpeta para BAM y archivos de alineamiento
STRINGTIE_DIR="${OUTPUT_DIR}/stringtie"  # Carpeta para los GTF de StringTie

# Parámetros
READ_FILES_COMMAND="gunzip -c" 
INTRON_MAX=200000
THREADS=8  

# Crear directorios de salida si no existen
mkdir -p "$OUTPUT_DIR"
mkdir -p "$QUALITY_DIR"
mkdir -p "$ALIGNMENT_DIR"
mkdir -p "$STRINGTIE_DIR"

STAR --runMode genomeGenerate \
     --genomeDir "$GENOME_DIR" \
     --genomeFastaFiles "$BASE_DIR/genome/Mus_musculus.GRCm39.dna.toplevel.fa" \
     --sjdbGTFfile "$ANNOTATION_GTF" \
     --genomeSAindexNbases 12

# Procesar todas las muestras
echo "Procesando muestras en: $SAMPLES_DIR"

for PREFIX in control hfd hfdpp; do
  for i in {1..4}; do
    SAMPLE_NAME="${PREFIX}${i}"
    SAMPLE_R1="${SAMPLES_DIR}/${SAMPLE_NAME}_R1.fq.gz"
    SAMPLE_R2="${SAMPLES_DIR}/${SAMPLE_NAME}_R2.fq.gz"
    SAMPLE_OUTPUT_PREFIX="${ALIGNMENT_DIR}/${SAMPLE_NAME}"  

    # Verificar si los archivos existen
    if [[ ! -f "$SAMPLE_R1" || ! -f "$SAMPLE_R2" ]]; then
      echo "Saltando $SAMPLE_NAME: archivos FASTQ no encontrados."
      continue
    fi

    echo "Procesando muestra: $SAMPLE_NAME"

    # Control de calidad con FASTQC
    fastqc -o "$QUALITY_DIR" "$SAMPLE_R1" "$SAMPLE_R2"

    # Alineamiento con STAR
    STAR --genomeDir "$GENOME_DIR" \
         --readFilesIn "$SAMPLE_R1" "$SAMPLE_R2" \
         --readFilesCommand "$READ_FILES_COMMAND" \
         --outSAMtype BAM SortedByCoordinate \
         --outSAMstrandField intronMotif \
         --outFilterIntronMotifs RemoveNoncanonical \
         --alignIntronMax "$INTRON_MAX" \
         --quantMode GeneCounts \
         --runThreadN "$THREADS" \
         --outFileNamePrefix "$SAMPLE_OUTPUT_PREFIX"

    # Indexar BAM
    echo "Indexando BAM para $SAMPLE_NAME"
    samtools index "${SAMPLE_OUTPUT_PREFIX}Aligned.sortedByCoord.out.bam"

    # Cuantificación a nivel de transcriptos con StringTie
    echo "Ejecutando StringTie en $SAMPLE_NAME"
    stringtie "${SAMPLE_OUTPUT_PREFIX}Aligned.sortedByCoord.out.bam" \
             -o "${STRINGTIE_DIR}/${SAMPLE_NAME}.gtf" \
             -p "$THREADS" \
             -G "$ANNOTATION_GTF" \
             -e -B

    echo "Muestra $SAMPLE_NAME completada."
  done
done

echo "sample,bam,gff" > "$OUTPUT_DIR/prep_input.csv"
for PREFIX in control hfd hfdpp; do
  for i in {1..4}; do
    SAMPLE_NAME="${PREFIX}${i}"
    echo "$SAMPLE_NAME,${ALIGNMENT_DIR}/${SAMPLE_NAME}Aligned.sortedByCoord.out.bam,${STRINGTIE_DIR}/${SAMPLE_NAME}.gtf" >> "$OUTPUT_DIR/prep_input.csv"
  done
done

echo "Generando matriz de conteos con prepDE.py"
# Generar matriz de conteos con prepDE.py
prepDE.py -i "$OUTPUT_DIR/prep_input.csv"



