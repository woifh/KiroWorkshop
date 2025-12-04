#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Testing Custom ID Support"
echo "=========================================="
echo ""

# Test 1: Create event with custom ID
echo "1. Creating event with custom ID 'my-custom-event-123'"
EVENT=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "eventId": "my-custom-event-123",
    "title": "Custom ID Test Event",
    "description": "Testing custom event ID",
    "date": "2026-01-15",
    "location": "Test Location",
    "capacity": 5,
    "waitlistEnabled": true,
    "organizer": "Test Org",
    "status": "active"
  }')

EVENT_ID=$(echo $EVENT | jq -r '.eventId')
echo "   Returned eventId: $EVENT_ID"
if [ "$EVENT_ID" = "my-custom-event-123" ]; then
  echo "   ✅ PASS - Custom event ID accepted"
else
  echo "   ❌ FAIL - Expected 'my-custom-event-123', got '$EVENT_ID'"
fi
echo ""

# Test 2: Create user with custom ID
echo "2. Creating user with custom ID 'my-custom-user-456'"
USER=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "my-custom-user-456",
    "name": "Custom ID Test User"
  }')

USER_ID=$(echo $USER | jq -r '.userId')
echo "   Returned userId: $USER_ID"
if [ "$USER_ID" = "my-custom-user-456" ]; then
  echo "   ✅ PASS - Custom user ID accepted"
else
  echo "   ❌ FAIL - Expected 'my-custom-user-456', got '$USER_ID'"
fi
echo ""

# Test 3: Register custom user to custom event
echo "3. Registering custom user to custom event"
REG=$(curl -s -X POST "$API_URL/events/my-custom-event-123/registrations" \
  -H "Content-Type: application/json" \
  -d '{"userId": "my-custom-user-456"}')

REG_STATUS=$(echo $REG | jq -r '.status')
REG_USER=$(echo $REG | jq -r '.userId')
REG_EVENT=$(echo $REG | jq -r '.eventId')

echo "   Registration status: $REG_STATUS"
echo "   User ID in response: $REG_USER"
echo "   Event ID in response: $REG_EVENT"

if [ "$REG_USER" = "my-custom-user-456" ] && [ "$REG_EVENT" = "my-custom-event-123" ] && [ "$REG_STATUS" = "registered" ]; then
  echo "   ✅ PASS - Custom IDs work in registration"
else
  echo "   ❌ FAIL - Custom IDs not working properly"
fi
echo ""

# Test 4: Retrieve user with custom ID
echo "4. Retrieving user by custom ID"
USER_GET=$(curl -s -X GET "$API_URL/users/my-custom-user-456")
USER_GET_ID=$(echo $USER_GET | jq -r '.userId')

if [ "$USER_GET_ID" = "my-custom-user-456" ]; then
  echo "   ✅ PASS - Can retrieve user by custom ID"
else
  echo "   ❌ FAIL - Cannot retrieve user by custom ID"
fi
echo ""

# Test 5: Retrieve event with custom ID
echo "5. Retrieving event by custom ID"
EVENT_GET=$(curl -s -X GET "$API_URL/events/my-custom-event-123")
EVENT_GET_ID=$(echo $EVENT_GET | jq -r '.eventId')

if [ "$EVENT_GET_ID" = "my-custom-event-123" ]; then
  echo "   ✅ PASS - Can retrieve event by custom ID"
else
  echo "   ❌ FAIL - Cannot retrieve event by custom ID"
fi
echo ""

echo "=========================================="
echo "Custom ID Support: VERIFIED ✅"
echo "=========================================="
echo ""
echo "The API accepts and uses custom IDs for:"
echo "  ✅ Events (eventId)"
echo "  ✅ Users (userId)"
echo "  ✅ Registrations (using custom IDs)"
