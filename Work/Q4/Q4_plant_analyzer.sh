#!/bin/bash
CSV_FILE=$1
if [ -z "$CSV_FILE" ]; then
    CSV_FILE=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "No CSV file found in the directory or provided as input!" >&2
    exit 1
fi

echo "Using CSV file: $CSV_FILE"

#Set up Virtual Environment outside the repository
VENV_PATH="$HOME/.venvs/plant_analysis_env"

if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "Virtual environment created at $VENV_PATH"
fi

#Activate the Virtual Environment
source "$VENV_PATH/bin/activate"

if [ -z "$VIRTUAL_ENV" ]; then
    echo "Failed to activate the virtual environment!" >&2
    exit 1
fi

echo "Virtual environment activated."

#Install dependencies
REQ_FILE="/home/somaeldein/LINUX_Course_Project/Work/Q2/requirements.txt"

if [ -f "$REQ_FILE" ]; then
    pip install -r "$REQ_FILE"
    echo "Required packages installed."
else
    echo "Requirements file not found! Skipping installation." >&2
fi

#Process CSV File and Run Python Script
OUTPUT_DIR="Diagrams"
mkdir -p "$OUTPUT_DIR"

LOG_FILE="Q4_HISTORY_FILE.log"
ERROR_LOG="Q4_ERROR_FILE.log"
> "$LOG_FILE"
> "$ERROR_LOG"

echo "Processing plants from $CSV_FILE" | tee -a "$LOG_FILE"

# Read the CSV file line by line, skipping the header
tail -n +2 "$CSV_FILE" | while IFS=, read -r plant_name param1 param2 param3; do
    PLANT_DIR="$OUTPUT_DIR/$plant_name"
    mkdir -p "$PLANT_DIR"
    
    echo "Processing plant: $plant_name with parameters: $param1, $param2, $param3" | tee -a "$LOG_FILE"
    
    # Run Python script
  python3 "/home/somaeldein/LINUX_Course_Project/Work/Q2/plant_analyzer.py" --plant "$plant_name" --height $(echo $param1 | tr -d '"') --leaf_count $(echo $param2 | tr -d '"') --dry_weight $(echo $param3 | tr -d '"')


    
    # Check if Python script ran successfully
    if [ $? -eq 0 ]; then
        echo "Successfully processed $plant_name" | tee -a "$LOG_FILE"
        mv *.png "$PLANT_DIR/" 2>/dev/null
    else
        echo "Error processing $plant_name. See $ERROR_LOG for details." | tee -a "$LOG_FILE"
    fi
done

#Archive plant folders
TIMESTAMP=$(date "+%Y_%m_%d_%H_%M_%S")
ZIP_FILE="/home/somaeldein/LINUX_Course_Project/BACKUPS/diagrams_Q4_${TIMESTAMP}.zip"
zip -r "$ZIP_FILE" "$OUTPUT_DIR" >>"$LOG_FILE" 2>>"$ERROR_LOG"

echo "Diagrams backed up to $ZIP_FILE" | tee -a "$LOG_FILE"
