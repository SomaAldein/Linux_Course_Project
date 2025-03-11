#!/bin/bash

# Script: Q4_plant_analyzer.sh

# Get CSV File Path
# If a CSV file is passed as an argument, use it
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

#Set Up Virtual Environment
#virtual environment path
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
# requirements file path
REQ_FILE="/home/somaeldein/LINUX_Course_Project/Work/Q2/requirements.txt"

# Install required packages if the requirements file exists
if [ -f "$REQ_FILE" ]; then
    pip install -r "$REQ_FILE"
    echo "Required packages installed."
else
    # If the requirements file does not exist, display an error message and exit
    echo "Requirements file not found!" >&2
    exit 1
fi


#Prepare Output Directories
# Define the output directory for storing generated diagrams
OUTPUT_DIR="Diagrams"
mkdir -p "$OUTPUT_DIR"  # Create the directory if it does not exist

# log files for the history and errors
LOG_FILE="Q4_HISTORY_FILE.log"
ERROR_LOG="Q4_ERROR_FILE.log"

# Clear previous log files
> "$LOG_FILE"
> "$ERROR_LOG"

# Print status message to the log file and the terminal
echo "Processing plants from $CSV_FILE" | tee -a "$LOG_FILE"


# Process CSV File and Run Python Script
# Reading the CSV file line by line, skipping the first line (header)
tail -n +2 "$CSV_FILE" | while IFS=, read -r plant_name param1 param2 param3; do

    # Create a folder for each plant inside the output directory (Diagrams)
    PLANT_DIR="$OUTPUT_DIR/$plant_name"
    mkdir -p "$PLANT_DIR"

    # Print plant information
    echo "Processing plant: $plant_name with parameters: $param1, $param2, $param3" | tee -a "$LOG_FILE"

    # Run the Python script to generate plant diagrams
  python3 "/home/somaeldein/LINUX_Course_Project/Work/Q2/plant_analyzer.py" \
    --plant "$plant_name" \
    --height $(echo $param1 | tr -d '"') \
    --leaf_count $(echo $param2 | tr -d '"') \
    --dry_weight $(echo $param3 | tr -d '"') \
    > "$PLANT_DIR/output.log" 2>>"$ERROR_LOG"

    
    # Check if the Python script executed successfully
    if [ $? -eq 0 ]; then
        echo "Successfully processed $plant_name" | tee -a "$LOG_FILE"
        mv *.png "$PLANT_DIR/" 2>/dev/null  # Move generated images to the plant's directory
    else
        echo "Error processing $plant_name. See $ERROR_LOG for details." | tee -a "$LOG_FILE"
    fi
done


# Deactivate Virtual Environment
deactivate

# Print confirmation
echo "Script execution completed successfully."
