# ⚠️ DEPLOYMENT REQUIRED

## Current Status

✅ **Code is ready** - All changes for custom ID support are complete
❌ **Not deployed yet** - The Lambda function needs to be updated

## What Works Now (Already Deployed)
- ✅ Custom Event IDs (`eventId` in request body)
- ✅ `waitlistEnabled` field support
- ✅ Flexible ID validation (accepts custom IDs like "test-user-1")

## What Needs Deployment
- ❌ Custom User IDs (`userId` in request body)

The user creation endpoint is still using the old code that ignores custom `userId` values.

## How to Deploy

### Option 1: Quick Deploy (Fastest)

```bash
chmod +x quick_deploy.sh
./quick_deploy.sh
```

This will automatically find and update your Lambda function.

### Option 2: Full CDK Deploy (Recommended)

```bash
cd infrastructure
bash package_lambda.sh
cdk deploy --require-approval never
```

### Option 3: Manual AWS CLI

```bash
# Find your Lambda function name
aws lambda list-functions --region us-west-2 | grep EventsApiLambda

# Update the function (replace FUNCTION_NAME)
aws lambda update-function-code \
  --function-name FUNCTION_NAME \
  --zip-file fileb://infrastructure/lambda_update.zip \
  --region us-west-2
```

## Verify Deployment

After deploying, run:

```bash
bash test_custom_ids.sh
```

All tests should pass, including:
- ✅ Custom event ID accepted
- ✅ Custom user ID accepted  
- ✅ Custom IDs work in registration
- ✅ Can retrieve by custom ID

## What's in the Update

The `infrastructure/lambda_update.zip` file contains:
1. Updated `database.py` - Uses custom `userId` if provided
2. Updated `models.py` - Accepts `userId` in UserCreate model
3. Updated `main.py` - Flexible ID validation

## Test Data Format

After deployment, the API will accept:

**Events:**
```json
{
  "eventId": "reg-test-event-789",
  "waitlistEnabled": true,
  ...
}
```

**Users:**
```json
{
  "userId": "test-user-1",
  "name": "Test User 1"
}
```

Both will use the provided custom IDs instead of generating UUIDs.
