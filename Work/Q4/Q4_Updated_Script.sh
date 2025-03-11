#!/bin/bash


# Default Parameter Values

CSV_FILE=""             # Path to input CSV file
OUTPUT_DIR="Diagrams"   # Directory to store generated diagrams
BACKUP_DIR="BACKUPS"    # Directory for storing ZIP backups
LOG_FILE="Q4_HISTORY_FILE.log"  # Main log file
ERROR_LOG="Q4_ERROR_FILE.log"  # Error log file
PYTHON_SCRIPT=""        # Path to the Python script (plant_analyzer.py)
CLEAN=false             # Flag to clean old diagrams before execution


# Function to Display Script Usage

usage() {
    echo "Usage: $0 [-p CSV_PATH] [-s PYTHON_SCRIPT] [-o OUTPUT_DIR] [-b BACKUP_DIR] [-l LOG_FILE] [-e ERROR_LOG] [-c]"
    echo "  -p | --path       Path to the CSV file"
    echo "  -s | --script     Path to the Python script (plant_analyzer.py)"
    echo "  -o | --output     Directory for output diagrams"
    echo "  -b | --backup     Directory for ZIP backups"
    echo "  -l | --log        Log file name"
    echo "  -e | --error-log  Error log file name"
    echo "  -c | --clean      Clean previous diagram directories before running"
    exit 1
}


# Parsing Command-Line Arguments

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--path) CSV_FILE="$2"; shift ;;
        -s|--script) PYTHON_SCRIPT="$2"; shift ;;  # New parameter for Python script path
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        -b|--backup) BACKUP_DIR="$2"; shift ;;
        -l|--log) LOG_FILE="$2"; shift ;;
        -e|--error-log) ERROR_LOG="$2"; shift ;;
        -c|--clean) CLEAN=true ;;  # If the `-c` flag is passed, it will clean old diagrams
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done


# Validate the CSV File Input
echo "DEBUG: CSV_FILE='$CSV_FILE'"
if [ -z "$CSV_FILE" ]; then
    # If no file is provided, attempt to find a CSV file in the current directory
    CSV_FILE=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: CSV file not found!" >&2
    usage  # Show usage instructions if no valid file is found
fi

echo "Using CSV file: $CSV_FILE"


# Validate the Python Script Path

if [ -z "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script path must be provided!" >&2
    usage
fi

if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT" >&2
    exit 1
fi

echo "Using Python script: $PYTHON_SCRIPT"

# Setting Up the Virtual Environment

VENV_PATH="$HOME/.venvs/plant_analysis_env"

# If the virtual environment does not exist, create it
if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv "$VENV_PATH"
    echo "Virtual environment created at $VENV_PATH"
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Ensure activation was successful
if [ -z "$VIRTUAL_ENV" ]; then
    echo "Failed to activate the virtual environment!" >&2
    exit 1
fi

echo "Virtual environment activated."


# Installing Required Python Packages

REQ_FILE="/home/somaeldein/LINUX_Course_Project/Work/Q2/requirements.txt"

if [ -f "$REQ_FILE" ]; then
    pip install -r "$REQ_FILE"
    echo "Required packages installed."
else
    echo "Requirements file not found! Skipping installation." >&2
fi


# Clean the Output Directory if Requested

if [ "$CLEAN" = true ]; then
    echo "Cleaning previous diagram directories..."
    rm -rf "$OUTPUT_DIR"/*
fi

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Clear previous log files
> "$LOG_FILE"
> "$ERROR_LOG"

echo "Processing plants from $CSV_FILE" | tee -a "$LOG_FILE"


# Read CSV File and Process Each Plant

tail -n +2 "$CSV_FILE" | while IFS=, read -r plant_name param1 param2 param3; do
    PLANT_DIR="$OUTPUT_DIR/$plant_name"
    mkdir -p "$PLANT_DIR"

    echo "Processing plant: $plant_name with parameters: $param1, $param2, $param3" | tee -a "$LOG_FILE"

    # Run the Python script with parameters
    python3 "$PYTHON_SCRIPT" \
        --plant "$plant_name" \
        --height $(echo $param1 | tr -d '"') \
        --leaf_count $(echo $param2 | tr -d '"') \
        --dry_weight $(echo $param3 | tr -d '"')

    # Check if the Python script executed successfully
    if [ $? -eq 0 ]; then
        echo "Successfully processed $plant_name" | tee -a "$LOG_FILE"
        mv *.png "$PLANT_DIR/" 2>/dev/null  # Move generated images to the plant's directory
    else
        echo "Error processing $plant_name. See $ERROR_LOG for details." | tee -a "$LOG_FILE"
    fi
done



# Deactivate the Virtual Environment
deactivate
