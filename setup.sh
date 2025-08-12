#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Update package lists and install necessary dependencies
sudo apt-get update -y
sudo apt-get install -y git curl unzip

# Download and install Flutter
git clone https://github.com/flutter/flutter.git --depth 1 -b stable ~/flutter

# Add Flutter to the PATH
export PATH="$PATH:$HOME/flutter/bin"

# Pre-cache Flutter dependencies
flutter precache

# Print Flutter version to verify installation
flutter --version

echo "Flutter setup completed successfully."
