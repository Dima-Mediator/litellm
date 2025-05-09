#!/bin/bash

# Exit script if any command fails
set -e

echo "Setting up LiteLLM for local development..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is required but not found. Please install Python 3.8 or newer."
    exit 1
fi

# Check if Node.js is installed (required for Prisma)
if ! command -v node &> /dev/null; then
    echo "Node.js is required for Prisma but not found. Please install Node.js."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -e .
pip install "litellm[proxy]"

# Install Prisma CLI and Python client
echo "Installing Prisma CLI..."
npm install -g prisma

echo "Installing prisma-client-py..."
pip install prisma

# Ensure prisma-client-py is available in PATH
export PRISMA_GENERATOR_BIN=$(python -c "import prisma; print(prisma.__path__[0])")/generator/

# Build Admin UI if enterprise version exists
if [ -f "enterprise/enterprise_ui/enterprise_colors.json" ]; then
    echo "Building Admin UI..."
    chmod +x docker/build_admin_ui.sh
    ./docker/build_admin_ui.sh
fi

# Generate Prisma client
echo "Generating Prisma client..."
prisma generate

# Load environment variables
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    source .env
else
    echo "Warning: No .env file found. Please make sure to set environment variables."
fi

# Check if config.yaml exists, create a default one if not
CONFIG_FILE="config.yaml"

# Run LiteLLM server with the config file
echo "Starting LiteLLM proxy server with config: $CONFIG_FILE"
litellm --config "$CONFIG_FILE" --port 4000 --detailed_debug 