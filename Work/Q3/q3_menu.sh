#!/bin/bash

# Directory where CSV files will be stored
CSV_DIR=~/LINUX_Course_Project/Work/Q3
# Variable to store the currently selected CSV file
CURRENT_CSV=""

# Function to create a new CSV file
create_csv_file() {
    echo -e "\nCreating a new CSV file..."
    read -p "Enter CSV file name: " filename
    CURRENT_CSV="$CSV_DIR/$filename.csv"
     # Initialize CSV with headers
    echo "Plant,Height,Leaf Count,Dry Weight" > "$CURRENT_CSV" 
    echo -e "\n New CSV created: $CURRENT_CSV\n"
}

# Function to select an existing CSV file
choose_csv_file() {
    echo -e "\nAvailable CSV files:"
    # List CSV files, suppress errors if no CSV files exist
    ls $CSV_DIR/*.csv 2>/dev/null  

    read -p "Enter CSV file name to select (without .csv extension): " filename
    if [[ -f "$CSV_DIR/$filename.csv" ]]; then
        CURRENT_CSV="$CSV_DIR/$filename.csv"
        echo -e "\n Current CSV set to: $CURRENT_CSV\n"
    else
        echo -e "\n Error: File '$filename.csv' does not exist. Please enter a valid file.\n"
    fi
}

# Function to display the content of the current CSV file
display_csv_file() {
    echo -e "\nDisplaying current CSV file...\n"
    if [[ -z "$CURRENT_CSV" ]]; then
        echo -e " No CSV file selected!\n"
    else
        cat "$CURRENT_CSV"
        echo -e "\n End of CSV file\n"
    fi
}

# Function to add a new row to the CSV file

add_plant_row() {
    echo -e "\nAdding a new plant entry..."
    if [[ -z "$CURRENT_CSV" ]]; then
        echo -e " No CSV file selected!\n"
        return
    fi

    read -p "Enter plant name: " plant
    
    while true; do
        read -p "Enter height values (space-separated, must be numbers): " height
        read -p "Enter leaf count values (space-separated, must be integers): " leaf_count
        read -p "Enter dry weight values (space-separated, must be numbers): " dry_weight

        # Convert inputs into arrays
        height_arr=($height)
        leaf_count_arr=($leaf_count)
        dry_weight_arr=($dry_weight)

        # Get the number of values in each input
        height_count=${#height_arr[@]}
        leaf_count_count=${#leaf_count_arr[@]}
        dry_weight_count=${#dry_weight_arr[@]}

        # Check if all counts match
        if [[ $height_count -ne $leaf_count_count || $height_count -ne $dry_weight_count ]]; then
            echo -e "\n Error: All attributes must have the same number of values! Try again.\n"
            continue
        fi

        # Validate height values (must be floating-point numbers)
        for h in "${height_arr[@]}"; do
            if ! [[ $h =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "\n Error: Height values must be numbers (e.g., 12.5 or 15). Try again.\n"
                continue 2
            fi
        done

        # Validate leaf count values (must be integers)
        for l in "${leaf_count_arr[@]}"; do
            if ! [[ $l =~ ^[0-9]+$ ]]; then
                echo -e "\n Error: Leaf count must be an integer (e.g., 3, 5, 10). Try again.\n"
                continue 2
            fi
        done

        # Validate dry weight values (must be floating-point numbers)
        for w in "${dry_weight_arr[@]}"; do
            if ! [[ $w =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "\n Error: Dry weight values must be numbers (e.g., 1.5 or 3.2). Try again.\n"
                continue 2
            fi
        done

        # If all inputs are valid, add the row to the CSV
        echo "$plant,\"$height\",\"$leaf_count\",\"$dry_weight\"" >> "$CURRENT_CSV"
        echo -e "\n New row added to $CURRENT_CSV\n"
        break
    done
}


# Function to run the Python (plant analyzer) script with plant data
run_python() {
    echo -e "\nRunning Python script for plant analysis..."
    if [[ -z "$CURRENT_CSV" ]]; then
        echo -e " No CSV file selected!\n"
        return
    fi
    read -p "Enter plant name to plot: " plant
    row=$(grep "^$plant," "$CURRENT_CSV")
    if [[ -z "$row" ]]; then
        echo -e "Plant not found!\n"
        return
    fi
    height=$(echo "$row" | cut -d',' -f2 | tr -d '"')
    leaf_count=$(echo "$row" | cut -d',' -f3 | tr -d '"')
    dry_weight=$(echo "$row" | cut -d',' -f4 | tr -d '"')
    python3 ~/LINUX_Course_Project/Work/Q2/plant_analyzer.py --plant "$plant" --height $height --leaf_count $leaf_count --dry_weight $dry_weight
    echo -e "\n Python script executed successfully!\n"
}

# Function to update an existing row
update_plant_row() {
    echo -e "\nUpdating plant data..."
    if [[ -z "$CURRENT_CSV" ]]; then
        echo -e " No CSV file selected!\n"
        return
    fi
    read -p "Enter plant name to update: " plant
    read -p "Enter new height values: " height
    read -p "Enter new leaf count values: " leaf_count
    read -p "Enter new dry weight values: " dry_weight
    awk -v plant="$plant" -v height="$height" -v leaf_count="$leaf_count" -v dry_weight="$dry_weight" \
        'BEGIN {FS=OFS=","} $1 == plant {$2="\"" height "\""; $3="\"" leaf_count "\""; $4="\"" dry_weight "\""} 1' "$CURRENT_CSV" > temp.csv && mv temp.csv "$CURRENT_CSV"
    echo -e "\n Updated $plant in $CURRENT_CSV\n"
}

# Function to delete a row based on plant name
delete_plant_row() {
    echo -e "\nDeleting plant entry..."
    if [[ -z "$CURRENT_CSV" ]]; then
        echo -e " No CSV file selected!\n"
        return
    fi
    read -p "Enter plant name to delete: " plant
    sed -i "/^$plant,/d" "$CURRENT_CSV"
    echo -e "\n Deleted $plant from $CURRENT_CSV\n"
}

# Function to calculate the average number of leaves for a plant
get_average_leaves() {
    leaf_counts=$(echo "$1" | tr -d '"')  # Remove quotes if any
    sum=0
    count=0
    for leaf in $leaf_counts; do
        if [[ "$leaf" =~ ^[0-9]+$ ]]; then  # Ensure it's a valid number
            sum=$((sum + leaf))
            count=$((count + 1))
        fi
    done
    if (( count == 0 )); then
        echo 0  # Prevent division by zero
    else
        echo $((sum / count))
    fi
}
# Function to find the plant with the highest average leaf count
highest_avg_leaf() {
    if [[ -z "$CURRENT_CSV" ]]; then
        echo "No CSV file selected!"
        return
    fi

    echo "Finding plant with the highest average leaf count..."

    best_plant=""
    max_avg=0

    while IFS=',' read -r plant height leaf_count dry_weight; do
        if [[ "$plant" == "Plant" ]]; then continue; fi  # Skip the header row
        avg=$(get_average_leaves "$leaf_count")  # Calculate average leaf count
        if [[ -n "$avg" && "$avg" -gt "$max_avg" ]]; then
            max_avg=$avg
            best_plant=$plant
        fi
    done < "$CURRENT_CSV"

    if [[ -n "$best_plant" ]]; then
        echo "Plant with highest avg leaves: $best_plant ($max_avg)"
    else
        echo "No valid data found in CSV."
    fi
}

# Main menu loop
while true; do
    echo -e "Menu:"
    echo "1) Create a CSV file and set it as the current file"
    echo "2) Select an existing CSV file as the current file"
    echo "3) Display the current CSV file"
    echo "4) Add a new row for a specific plant"
    echo "5) Run the improved Python script with parameters for a specific plant to generate diagrams"
    echo "6) Update values in a specific row in the file based on the plant name"
    echo "7) Delete a row by row index or by plant name"
    echo "8) Print the plant with the highest average leaf count"
    echo "9) Exit"
    echo -e "\n"
    read -p "Enter your choice: " choice
    case $choice in
        1) create_csv_file ;;
        2) choose_csv_file ;;
        3) display_csv_file ;;
        4) add_plant_row ;;
        5) run_python ;;
        6) update_plant_row;;
        7) delete_plant_row ;;
        8) highest_avg_leaf ;;
        9) echo -e "Exiting... Goodbye!\n"; exit ;;
        *) echo -e "\n Invalid choice! Try again.\n";;
    esac
done
