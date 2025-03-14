#!/bin/bash
# Default Parameter Values
CSV_FILE=""                
OUTPUT_DIR="Diagrams"      
LOG_FILE="Q4_2_HISTORY_FILE.log"  
ERROR_LOG="Q4_2_ERROR_FILE.log"   
PYTHON_SCRIPT=""           
REQ_FILE=""                
VENV_PATH="$HOME/.venvs/plant_analysis_env"  

# Function to Show Usage Instructions
usage() {
    echo "Usage: $0 [-p CSV_PATH] [-s PYTHON_SCRIPT] [-r REQUIREMENTS_FILE] [-o OUTPUT_DIR] [-l LOG_FILE] [-e ERROR_LOG]"
    echo "  -p | --path        Path to the CSV file"
    echo "  -s | --script      Path to the Python script (plant_analyzer.py)"
    echo "  -r | --requirements Path to requirements.txt"
    echo "  -o | --output      Directory for output diagrams"
    echo "  -l | --log         Log file name"
    echo "  -e | --error-log   Error log file name"
    exit 1
}

# Parsing Command-Line Arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--path) CSV_FILE="$2"; shift ;;
        -s|--script) PYTHON_SCRIPT="$2"; shift ;; 
        -r|--requirements) REQ_FILE="$2"; shift ;;
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        -l|--log) LOG_FILE="$2"; shift ;;
        -e|--error-log) ERROR_LOG="$2"; shift ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# Validate CSV File
if [ -z "$CSV_FILE" ]; then
    CSV_FILE=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
fi

if [ ! -f "$CSV_FILE" ]; then
    echo " Error: CSV file not found!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    usage
fi

echo "Using CSV file: $CSV_FILE" | tee -a "$LOG_FILE"

# Function to Validate CSV Structure
validate_csv_structure() {
    echo "Validating CSV structure..." | tee -a "$LOG_FILE"

    if [ ! -s "$CSV_FILE" ]; then
        echo " Error: CSV file is empty!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    header=$(head -n 1 "$CSV_FILE")
    expected_header="Plant,Height,Leaf Count,Dry Weight"

    if [[ "$header" != "$expected_header" ]]; then
        echo "Error: CSV header is incorrect! Expected format: $expected_header" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    invalid_rows=$(tail -n +2 "$CSV_FILE" | awk -F',' 'NF!=4 {print NR+1}')
    if [[ -n "$invalid_rows" ]]; then
        echo "Error: Invalid CSV format detected on lines: $invalid_rows" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    echo "CSV file is valid." | tee -a "$LOG_FILE"
}

# Call validation function
validate_csv_structure

# Validate Python Script
if [ -z "$PYTHON_SCRIPT" ]; then
    echo " Error: Python script path must be provided!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    usage
fi

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    exit 1
fi

echo "Using Python script: $PYTHON_SCRIPT" | tee -a "$LOG_FILE"

# Validate Requirements File
if [ -z "$REQ_FILE" ]; then
    echo " Error: Requirements file path must be provided!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    usage
fi

if [ ! -f "$REQ_FILE" ]; then
    echo "Error: Requirements file not found at $REQ_FILE" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    exit 1
fi

echo "Using requirements file: $REQ_FILE" | tee -a "$LOG_FILE"

# Setting Up the Virtual Environment
if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "Virtual environment created at $VENV_PATH" | tee -a "$LOG_FILE"
fi

# Activate Virtual Environment
source "$VENV_PATH/bin/activate"
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Failed to activate the virtual environment!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    exit 1
fi
echo "Virtual environment activated." | tee -a "$LOG_FILE"

# Install Required Python Packages
pip install --quiet -r "$REQ_FILE"

# Ensure Output Directory Exists
mkdir -p "$OUTPUT_DIR"

# Clear Previous Logs
> "$LOG_FILE"
> "$ERROR_LOG"

echo "Processing plants from $CSV_FILE" | tee -a "$LOG_FILE"

# Read CSV File and Process Each Plant
tail -n +2 "$CSV_FILE" | while IFS=, read -r plant_name param1 param2 param3; do
    PLANT_DIR="$OUTPUT_DIR/$plant_name"
    mkdir -p "$PLANT_DIR"

    echo "Processing plant: $plant_name with parameters: $param1, $param2, $param3" | tee -a "$LOG_FILE"

    # Run the Python script with error logging
    python3 "$PYTHON_SCRIPT" \
        --plant "$plant_name" \
        --height $(echo $param1 | tr -d '"') \
        --leaf_count $(echo $param2 | tr -d '"') \
        --dry_weight $(echo $param3 | tr -d '"') \
        > "$PLANT_DIR/output.log" 2>> "$ERROR_LOG"

    if [ $? -eq 0 ]; then
        echo "Successfully processed $plant_name" | tee -a "$LOG_FILE"
        num_images=$(ls *.png 2>/dev/null | wc -l)
        if [ "$num_images" -gt 0 ]; then
            echo "Found $num_images image(s), moving to $PLANT_DIR" | tee -a "$LOG_FILE"
            mv *.png "$PLANT_DIR/" 2>/dev/null
        else
            echo "Warning: No images were generated for $plant_name!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        fi
    else
        echo " Error processing $plant_name. See $ERROR_LOG for details." | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
    fi
done

# Deactivate Virtual Environment
deactivate
echo "Script execution completed successfully." | tee -a "$LOG_FILE"
