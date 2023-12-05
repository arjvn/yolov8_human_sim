# __module__ = "peoplesanspeople+yolov8"
# __author__ = "Arjun Agrawal"
# __email__ = "arjunkozik@gmail.com"
# __version__ = "v1.0"

FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Install Python 3 and pip
RUN apt-get update && \
    apt-get install -y --no-install-recommends vim && \
    apt-get install -y python3 && \
    apt-get install python-is-python3 && \
    apt-get install -y python3-pip && \
    apt-get install -y ffmpeg libsm6 libxext6 && \
    apt-get install -y wget unzip && \
    apt-get install -y openssh-client git && \
    apt install bc

# Install Vulkan
RUN wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-focal.list http://packages.lunarg.com/vulkan/lunarg-vulkan-focal.list && \
    apt-get update && \
    apt-get install -y nvidia-settings vulkan-utils

# # Install PyTorch with CUDA support
# RUN pip3 install --no-cache-dir torch torchvision torchaudio -f https://download.pytorch.org/whl/cu111/torch_stable.html

# Clone in requirements
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY requirements.txt /usr/src/app/requirements.txt

# Install pip packages
RUN python3 -m pip install --no-cache-dir --upgrade pip wheel && \
    pip3 install --no-cache -r requirements.txt
RUN wget https://peoplesanspeople.blob.core.windows.net/peoplesanspeople-gha-binaries/StandaloneLinux64_39ff5eb9ab4ce79440a3f743ebeb4f7b3c967024.zip && \
    unzip StandaloneLinux64_39ff5eb9ab4ce79440a3f743ebeb4f7b3c967024.zip && \
    rm -rf StandaloneLinux64_39ff5eb9ab4ce79440a3f743ebeb4f7b3c967024.zip

# Copy key files
COPY PeopleSansPeople/peoplesanspeople_binaries /usr/src/app/PeopleSansPeople/peoplesanspeople_binaries
COPY src/train_yolov8.py /usr/src/app/yolov8/train.py
COPY datasets/create_yolo_labels.py /usr/src/app/datasets/create_yolo_labels.py


###########################
# Run peoplesanspeople simulation
###########################
## BUG: this is not working yet so just copying in the dataset produced locally for now
# RUN cd peoplesanspeople_binaries && \ 
#     bash run.sh -t Linux -d build/StandaloneLinux64 -f scenarioConfiguration.json -l build/StandaloneLinux64/log.txt
COPY PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1 /usr/src/app/PeopleSansPeople/HDRP_RenderPeople_2020.1.17f1

###########################
# Train YOLOv8
###########################
RUN python3 datasets/create_yolo_labels.py
CMD cd yolov8 && python3 train.py