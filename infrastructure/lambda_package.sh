#!/bin/bash
set -e

echo "Creating Lambda deployment package..."

# Create temp directory
mkdir -p /tmp/lambda_package
cd /tmp/lambda_package

# Copy backend files
cp -r $OLDPWD/../backend/* .

# Install dependencies
pip3 install -r requirements.txt -t .

# Create ZIP
zip -r lambda_package.zip .

# Move to infrastructure directory
mv lambda_package.zip $OLDPWD/

echo "Lambda package created: lambda_package.zip"
