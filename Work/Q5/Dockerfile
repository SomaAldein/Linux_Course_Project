# Use an official Python runtime as a parent image
FROM python:3.10

# Set the working directory inside the container
WORKDIR /app

# Copy only the required files
COPY plant_analyzer.py requirements.txt ./

# Install required Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Use ENTRYPOINT to allow passing arguments to the script
ENTRYPOINT ["python", "plant_analyzer.py"]
