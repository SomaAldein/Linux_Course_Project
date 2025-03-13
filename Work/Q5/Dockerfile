# Use an official Python runtime as a parent image
FROM python:3.10

# Set the working directory inside the container
WORKDIR /app

# Copy the local files to the container
COPY . .

# Install required Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Use ENTRYPOINT to correctly pass arguments
ENTRYPOINT ["python", "plant_analyzer.py"]
