#!/bin/bash

# Expire Files - Run Script
# This script compiles and runs the Expire Files application

echo "Expire Files - macOS File Expiration Manager"
echo "============================================="

echo "Cleaning build artifacts..."
swift package clean

echo "Compiling Expire Files in debug mode..."
swift build
if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi
echo "Compilation successful!"

echo "Starting ExpireFiles in the background..."

# Copy the compiled binary to the app bundle
cp .build/debug/ExpireFiles ExpireFiles.app/Contents/MacOS/

# Run the application in the background
nohup ./ExpireFiles.app/Contents/MacOS/ExpireFiles > /dev/null 2>&1 &

echo "Application started."
echo "The app will run as a status bar icon."
echo "To stop the application, click the icon and select 'Quit'."