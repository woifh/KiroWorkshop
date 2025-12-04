#!/bin/bash

# Package Lambda function without Docker
set -e

echo "Packaging Lambda function..."

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKAGE_DIR="$SCRIPT_DIR/lambda_package"
BACKEND_DIR="$SCRIPT_DIR/../backend"

# Create temporary directory
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy backend code
echo "Copying backend code..."
cp "$BACKEND_DIR"/*.py "$PACKAGE_DIR/"

# Install dependencies
echo "Installing dependencies..."
pip3 install -r "$BACKEND_DIR/requirements.txt" -t "$PACKAGE_DIR/" --platform manylinux2014_x86_64 --only-binary=:all: --python-version 3.11

# Remove unnecessary files to reduce size
echo "Cleaning up..."
cd "$PACKAGE_DIR"
rm -rf boto3* botocore* pip* setuptools* wheel* *.dist-info __pycache__

echo "Package created in $PACKAGE_DIR/"
