#!/bin/bash

# Ask user for experiment name
read -p "Enter the experiment name (press Enter for default value): " experiment_name

# see if you want to create a conda environment

# Set default value if user input is empty
experiment_name=${experiment_name:-default-experiment}

# Set experiment name as environment variable for docker-compose
export YOLOv8_EXPERIMENT_NAME="$experiment_name"

# Generate dataset
git clone https://github.com/Unity-Technologies/PeopleSansPeople.git
cd PeopleSansPeople/peoplesanspeople_binaries
wget https://peoplesanspeople.blob.core.windows.net/peoplesanspeople-gha-binaries/StandaloneLinux64_39ff5eb9ab4ce79440a3f743ebeb4f7b3c967024.zip
unzip StandaloneLinux64_39ff5eb9ab4ce79440a3f743ebeb4f7b3c967024.zip
bash run.sh -t Linux -d build/StandaloneLinux64 -f scenarioConfiguration.json -l build/StandaloneLinux64/log.txt
cd ../..
dataset_path=$(grep -oP 'Dataset written to \K.*' PeopleSansPeople/peoplesanspeople_binaries/build/StandaloneLinux64/log.txt)
mkdir -p "PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1"
cp -r "$dataset_path"/* "PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1"

# Build and run yolov8 docker
make build-run