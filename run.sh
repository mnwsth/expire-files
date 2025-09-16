#!/bin/bash

# Expire Files - Run Script
# This script compiles and runs the Expire Files application

echo "Expire Files - macOS File Expiration Manager"
echo "============================================="

echo "Compiling Expire Files in debug mode..."
swift build
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi
echo "Compilation successful!"

echo "Starting Expire Files (debug mode)..."
echo "The app will monitor your Downloads folder for new files."
echo "Press Ctrl+C to stop the application."
echo ""

# Run the application
.build/debug/ExpireFiles
