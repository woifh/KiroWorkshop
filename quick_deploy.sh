#!/bin/bash

echo "Quick Lambda Deployment"
echo "======================="
echo ""

# Check if AWS credentials are configured
if ! aws sts get-caller-identity --no-verify-ssl > /dev/null 2>&1; then
  echo "❌ AWS credentials not configured"
  echo ""
  echo "Please configure AWS credentials first:"
  echo "  aws configure"
  echo ""
  echo "Or set environment variables:"
  echo "  export AWS_ACCESS_KEY_ID=..."
  echo "  export AWS_SECRET_ACCESS_KEY=..."
  echo "  export AWS_SESSION_TOKEN=..."
  exit 1
fi

echo "✅ AWS credentials found"
echo ""

# Get Lambda function name
FUNCTION_NAME=$(aws lambda list-functions --region us-west-2 --no-verify-ssl --no-cli-pager 2>/dev/null | \
  jq -r '.Functions[] | select(.FunctionName | contains("EventsApiLambda")) | .FunctionName' | head -1)

if [ -z "$FUNCTION_NAME" ]; then
  echo "❌ Could not find Lambda function"
  echo ""
  echo "Please deploy using CDK:"
  echo "  cd infrastructure"
  echo "  bash package_lambda.sh"
  echo "  cdk deploy"
  exit 1
fi

echo "Found Lambda function: $FUNCTION_NAME"
echo ""

# Update Lambda function
echo "Updating Lambda function code..."
aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://infrastructure/lambda_update.zip \
  --region us-west-2 \
  --no-verify-ssl \
  --no-cli-pager > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "✅ Lambda function updated successfully"
  echo ""
  echo "Waiting for update to complete..."
  sleep 5
  echo "✅ Deployment complete"
  echo ""
  echo "Test the API:"
  echo "  bash test_custom_ids.sh"
else
  echo "❌ Failed to update Lambda function"
  echo ""
  echo "Try deploying with CDK instead:"
  echo "  cd infrastructure"
  echo "  bash package_lambda.sh"
  echo "  cdk deploy"
  exit 1
fi
