import argparse
import matplotlib.pyplot as plt

# Argument parsing
args_parser = argparse.ArgumentParser(description="Plot plant growth data")
# The '--plant' argument is a required string argument that specifies the plant name
args_parser.add_argument("--plant", type=str, required=True)

# Defines a required command-line argument '--height' that accepts a list of float values
# The nargs="+" argument allows the user to input multiple values for the same argument
# The required=True argument ensures that the '--height' argument is mandatory
# The type=float argument specifies that the values should be converted to float
args_parser.add_argument("--height", type=float, nargs="+", required=True)

# The same logic applies to the '--leaf_count' and '--dry_weight' arguments
args_parser.add_argument("--leaf_count", type=int, nargs="+", required=True)
args_parser.add_argument("--dry_weight", type=float, nargs="+", required=True)

# Parses the command-line arguments provided by the user
args = args_parser.parse_args()

# Ensure all lists have the same number of values
if not (len(args.height) == len(args.leaf_count) == len(args.dry_weight)):
    raise ValueError("Error: All input lists must have the same number of values")



# Print plant data
print(f"Plant: {args.plant}")
print(f"Height data: {args.height} cm")
print(f"Leaf count data: {args.leaf_count}")
print(f"Dry weight data: {args.dry_weight} g")

# Scatter Plot - Height vs Leaf Count
plt.figure(figsize=(10, 6))
plt.scatter(args.height, args.leaf_count, color='b')
plt.title(f'Height vs Leaf Count for {args.plant}')
plt.xlabel('Height (cm)')
plt.ylabel('Leaf Count')
plt.grid(True)
plt.savefig(f"{args.plant}_scatter.png")
plt.close()  # Close the plot to prepare for the next one

# Histogram - Distribution of Dry Weight
plt.figure(figsize=(10, 6))
plt.hist(args.dry_weight, bins=5, color='g', edgecolor='black')
plt.title(f'Histogram of Dry Weight for {args.plant}')
plt.xlabel('Dry Weight (g)')
plt.ylabel('Frequency')
plt.grid(True)
plt.savefig(f"{args.plant}_histogram.png")
plt.close()  # Close the plot to prepare for the next one

# Line Plot - Plant Height Over Time
weeks = [f"Week {i+1}" for i in range(len(args.height))]  # Generate week labels dynamically
plt.figure(figsize=(10, 6))
plt.plot(weeks, args.height, marker='o', color='r')
plt.title(f'{args.plant} Height Over Time')
plt.xlabel('Week')
plt.ylabel('Height (cm)')
plt.grid(True)
plt.savefig(f"{args.plant}_line_plot.png")
plt.close()  

# Output confirmation
print(f"Generated plots for {args.plant}:")
print(f"Scatter plot saved as {args.plant}_scatter.png")
print(f"Histogram saved as {args.plant}_histogram.png")
print(f"Line plot saved as {args.plant}_line_plot.png")