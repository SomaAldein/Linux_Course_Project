#!/bin/bash

# Get CSV File Path
CSV_FILE=$1

# If no CSV file is passed, search for one in the current directory
if [ -z "$CSV_FILE" ]; then
    CSV_FILE=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
fi

# If the CSV file still does not exist, exit with an error
if [ ! -f "$CSV_FILE" ]; then
    echo "No CSV file found in the directory or provided as input!" >&2
    exit 1
fi

# Display the CSV file being used
echo "CSV file: $CSV_FILE"

# Function to validate CSV structure
validate_csv_structure() {
    echo "Validating CSV structure..." | tee -a "$LOG_FILE"

    # Ensure log files exist before using them
    touch "$LOG_FILE" "$ERROR_LOG"

    # Check if file is empty
    if [ ! -s "$CSV_FILE" ]; then
        echo "Error: CSV file is empty!" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    # Read the first line (header)
    header=$(head -n 1 "$CSV_FILE")
    expected_header="Plant,Height,Leaf Count,Dry Weight"

    # Check if header matches the expected format
    if [[ "$header" != "$expected_header" ]]; then
        echo "Error: CSV header is incorrect! Expected format: $expected_header" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    # Validate that each row has exactly 4 columns
    invalid_rows=$(tail -n +2 "$CSV_FILE" | awk -F',' 'NF!=4 {print NR+1}')
    
    if [[ -n "$invalid_rows" ]]; then
        echo " Error: Invalid CSV format detected on lines: $invalid_rows" | tee -a "$LOG_FILE" | tee -a "$ERROR_LOG"
        exit 1
    fi

    echo "CSV file is valid." | tee -a "$LOG_FILE"
}
LOG_FILE="Q4_HISTORY_FILE.log"
ERROR_LOG="Q4_ERROR_FILE.log"

> "$LOG_FILE"
> "$ERROR_LOG"

# Call validation function
validate_csv_structure


# Set Up Virtual Environment
VENV_PATH="$HOME/.venvs/plant_analysis_env"

# If the virtual environment does not exist, create it
if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "Virtual environment created at $VENV_PATH"
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Check if it was successful
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Failed to activate the virtual environment!" >&2
    exit 1
fi

echo "Virtual environment activated."


# Install Required Python Packages from the Requirements File
REQ_FILE="/home/somaeldein/LINUX_Course_Project/Work/Q2/requirements.txt"

if [ -f "$REQ_FILE" ]; then
    pip install -r "$REQ_FILE"
    echo "Required packages installed."
else
    echo "Requirements file not found!" >&2
    exit 1
fi


# Prepare Output Directories
OUTPUT_DIR="Diagrams"
mkdir -p "$OUTPUT_DIR"


echo "Processing plants from $CSV_FILE" | tee -a "$LOG_FILE"


# Process CSV File and Run Python Script
tail -n +2 "$CSV_FILE" | while IFS=, read -r plant_name param1 param2 param3; do

    PLANT_DIR="$OUTPUT_DIR/$plant_name"
    mkdir -p "$PLANT_DIR"

    echo "Processing plant: $plant_name with parameters: $param1, $param2, $param3" | tee -a "$LOG_FILE"

    python3 "/home/somaeldein/LINUX_Course_Project/Work/Q2/plant_analyzer.py" \
        --plant "$plant_name" \
        --height $(echo $param1 | tr -d '"') \
        --leaf_count $(echo $param2 | tr -d '"') \
        --dry_weight $(echo $param3 | tr -d '"') \
        > "$PLANT_DIR/output.log" 2>>"$ERROR_LOG"

    if [ $? -eq 0 ]; then
        echo "Successfully processed $plant_name" | tee -a "$LOG_FILE"
        mv *.png "$PLANT_DIR/" 2>/dev/null
    else
        echo "Error processing $plant_name. See $ERROR_LOG for details." | tee -a "$LOG_FILE"
    fi
done


# Deactivate Virtual Environment
deactivate

echo "Script execution completed successfully."
