#!/bin/bash

# ==========================================
# Pace AI Research - Voice Assistant Setup
# Speech-to-Text + LLM + Text-to-Speech Pipeline
# Target OS: Ubuntu 22.04 / 24.04 LTS
# Target GPU: NVIDIA (CUDA-capable)
# ==========================================

set -e  # Exit immediately if a command exits with a non-zero status.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/myenv"

echo "🚀 Pace AI Research - Voice Assistant Setup"
echo "==========================================="

# --- 1. Check Python version ---
PYTHON_CMD=""
for cmd in python3.11 python3.10 python3; do
    if command -v $cmd &> /dev/null; then
        PYTHON_CMD=$cmd
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Python 3.10+ is required. Please install Python first."
    exit 1
fi

echo "✅ Found Python: $($PYTHON_CMD --version)"

# --- 2. Install system dependencies ---
echo "📦 Installing system dependencies..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y ffmpeg python3-venv python3-dev build-essential
elif command -v dnf &> /dev/null; then
    sudo dnf install -y ffmpeg python3-devel gcc gcc-c++
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm ffmpeg python
else
    echo "⚠️  Could not detect package manager. Please install ffmpeg manually."
fi

# --- 3. Create Python virtual environment ---
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creating virtual environment at $VENV_DIR..."
    $PYTHON_CMD -m venv "$VENV_DIR"
else
    echo "✅ Virtual environment already exists."
fi

# --- 4. Activate and install dependencies ---
echo "📥 Installing Python dependencies..."
source "$VENV_DIR/bin/activate"

# Upgrade pip first
pip install --upgrade pip

# Install PyTorch with CUDA support (adjust for your CUDA version)
if command -v nvidia-smi &> /dev/null; then
    echo "🎮 NVIDIA GPU detected. Installing PyTorch with CUDA..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
else
    echo "💻 No NVIDIA GPU detected. Installing CPU-only PyTorch..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
fi

# Install remaining requirements
pip install -r "$PROJECT_DIR/requirements.txt"

# --- 5. Create model cache directory ---
mkdir -p "$PROJECT_DIR/model_cache"

# --- 6. SSL Certificate Setup Info ---
echo ""
echo "==========================================="
echo "🎉 Setup Complete!"
echo "==========================================="
echo ""
echo "To run the server:"
echo "  cd $PROJECT_DIR"
echo "  source myenv/bin/activate"
echo "  SERVER_PORT=6942 python server.py"
echo ""
echo "For HTTPS (recommended for microphone access):"
echo "  1. Copy your SSL certificates to cert.pem and key.pem"
echo "  2. Or use Let's Encrypt: sudo certbot certonly --standalone -d yourdomain.com"
echo "  3. Copy certs: sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem cert.pem"
echo "               sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem key.pem"
echo ""
echo "Environment Variables:"
echo "  SERVER_PORT=6942         # Server port (default: 3001)"
echo "  SERVER_HOST=0.0.0.0      # Bind address"
echo "  EDGE_TTS_VOICE=female_us # TTS voice (female_us, male_us, female_uk, male_uk)"
echo "  LLM_MODEL_ID=...         # Override LLM model"
echo """
