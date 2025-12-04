# Deploy Updates for Custom ID Support

## Changes Made

The API has been updated to support:
1. **Custom Event IDs** - Can specify `eventId` in POST /events request
2. **Custom User IDs** - Can specify `userId` in POST /users request  
3. **waitlistEnabled field** - Alias for `hasWaitlist` field
4. **Flexible ID validation** - Accepts both UUIDs and custom alphanumeric IDs

## To Deploy

### Option 1: Using CDK (Recommended)

```bash
cd infrastructure
bash package_lambda.sh
cdk deploy --require-approval never
```

### Option 2: Direct Lambda Update (if AWS credentials are configured)

```bash
# The lambda package is already zipped at infrastructure/lambda_update.zip
aws lambda update-function-code \
  --function-name BackendStack-EventsApiLambda* \
  --zip-file fileb://infrastructure/lambda_update.zip \
  --region us-west-2
```

## Test After Deployment

Run the exact format test to verify all endpoints work:

```bash
bash test_exact_format.sh
```

Expected output: All tests should PASS with HTTP 200/201 status codes.

## What the Tests Expect

The test framework will send requests with:

### Events
```json
{
  "eventId": "reg-test-event-789",
  "waitlistEnabled": true,
  ...
}
```

### Users
```json
{
  "userId": "test-user-1",
  "name": "Test User 1"
}
```

### Registrations
```json
{
  "userId": "test-user-1"
}
```

All these formats are now supported!

## Backward Compatibility

The API still supports:
- Auto-generated UUIDs (if no custom ID provided)
- `hasWaitlist` field (original field name)
- UUID-format IDs

No breaking changes to existing functionality.
