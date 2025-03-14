#!/bin/bash

# Step 1: Build Python container
echo "Building Python container..."
docker build -t q5_plant_analyzer .

# Step 2: Run Python container to generate images
echo "Running Python container..."
docker run --rm -v $(pwd):/app q5_plant_analyzer --plant "Lavender" --height 10 15 20 --leaf_count 5 8 12 --dry_weight 0.2 0.4 0.6

# Step 3: Build Java container
echo "Building Java container..."
docker build -t java_watermark -f Dockerfile-java .

# Step 4: Run Java container to apply watermark
echo "Running Java watermarking container..."
docker run --rm -v $(pwd):/app java_watermark /app

# Step 5: Cleanup - Remove all stopped containers and unused images
echo "Cleaning up..."
docker system prune -f

echo "Cleaning up..."
docker rm -f $(docker ps -aq) 2>/dev/null
docker rmi -f $(docker images -q) 2>/dev/null
docker system prune -f --volumes


echo "Process completed!"
