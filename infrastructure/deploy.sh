#!/bin/bash

# Deploy script for Events API
set -e

echo "Installing CDK dependencies..."
python3 -m pip install --user aws-cdk-lib constructs

echo "Synthesizing CDK stack..."
python3 app.py

echo "Deploying with CDK..."
cdk bootstrap --no-verify-ssl
cdk deploy --no-verify-ssl --require-approval never

echo "Deployment complete!"
