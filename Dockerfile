# UPDATED for Ubuntu 24.04 (Noble Numbat)
# Base image matches the host OS version for consistency.
# Verify this tag exists on Docker Hub; if CUDA 13 on 24.04 isn't out yet,
# fallback to nvidia/cuda:12.4.1-cudnn-runtime-ubuntu24.04
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

# 1. PYTHONUNBUFFERED: Stop Python from buffering stdout (easier debugging).
# 2. DEBIAN_FRONTEND: Prevent interactive prompts.
# 3. PIP_BREAK_SYSTEM_PACKAGES: Ubuntu 24.04 uses Python 3.12+, which blocks 
#    global pip installs by default (PEP 668). Since we are in a container, 
#    we force it to allow system-wide installs.
ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1

# Update apt and install system dependencies.
# Ubuntu 24.04 ships with Python 3.12.
# - python3-pip/dev: Essential.
# - build-essential: For compiling C extensions.
# - ffmpeg: CRITICAL for audio processing (Whisper/TTS).
# - portaudio19-dev: Needed for PyAudio/sounddevice.
# - git: To pull dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    build-essential \
    ffmpeg \
    portaudio19-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Symlink python3 to python just in case scripts rely on 'python'
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set the working directory container-side
WORKDIR /app

# Copy requirements first to leverage Docker cache layers.
COPY requirements.txt .

# Install Python dependencies.
# NOTE: If using CUDA 13, you might need the nightly index for PyTorch.
# We use --no-cache-dir to keep the image size down.
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port
EXPOSE 3001

# The default command to run when the container starts.
CMD ["python", "orchestrator.py"]
