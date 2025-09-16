#!/bin/bash

# Expire Files - Run Script
# This script compiles and runs the Expire Files application

echo "Expire Files - macOS File Expiration Manager"
echo "============================================="

# Check if already compiled
if [ ! -f ".build/release/ExpireFiles" ]; then
    echo "Compiling Expire Files..."
    swift build -c release
    if [ $? -ne 0 ]; then
        echo "Compilation failed!"
        exit 1
    fi
    echo "Compilation successful!"
fi

echo "Starting Expire Files..."
echo "The app will monitor your Downloads folder for new files."
echo "Press Ctrl+C to stop the application."
echo ""

# Run the application
echo "Starting Expire Files (fixed version)..."
.build/release/ExpireFiles
