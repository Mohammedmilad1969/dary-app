#!/bin/bash
echo "Building Dary Properties for Android..."
echo

echo "Step 1: Cleaning previous builds..."
flutter clean
echo

echo "Step 2: Getting dependencies..."
flutter pub get
echo

echo "Step 3: Building debug APK..."
flutter build apk --debug --split-per-abi
echo

echo "Build completed! APK location:"
echo "build/app/outputs/flutter-apk/"
echo
echo "To install on connected device, run:"
echo "flutter install"
echo
