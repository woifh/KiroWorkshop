#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Testing User Registration API"
echo "=========================================="
echo ""

# Test 1: Create a user
echo "1. Creating a user..."
USER_RESPONSE=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe"}')
echo "Response: $USER_RESPONSE"
USER_ID=$(echo $USER_RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User ID: $USER_ID"
echo ""

# Test 2: Create another user
echo "2. Creating another user..."
USER2_RESPONSE=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Smith"}')
echo "Response: $USER2_RESPONSE"
USER2_ID=$(echo $USER2_RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 2 ID: $USER2_ID"
echo ""

# Test 3: Get user
echo "3. Getting user details..."
curl -s -X GET "$API_URL/users/$USER_ID" | jq '.'
echo ""

# Test 4: Create an event with capacity
echo "4. Creating an event with capacity 2 and waitlist..."
EVENT_RESPONSE=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Workshop",
    "description": "Learn about cloud computing",
    "date": "2025-12-15",
    "location": "Seattle, WA",
    "capacity": 2,
    "hasWaitlist": true,
    "organizer": "Tech Corp",
    "status": "active"
  }')
echo "Response: $EVENT_RESPONSE"
EVENT_ID=$(echo $EVENT_RESPONSE | grep -o '"eventId":"[^"]*"' | cut -d'"' -f4)
echo "Event ID: $EVENT_ID"
echo ""

# Test 5: Register first user for event
echo "5. Registering first user for event..."
curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER_ID\"}" | jq '.'
echo ""

# Test 6: Register second user for event
echo "6. Registering second user for event..."
curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}" | jq '.'
echo ""

# Test 7: Create third user and try to register (should go to waitlist)
echo "7. Creating third user and registering (should go to waitlist)..."
USER3_RESPONSE=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob Wilson"}')
USER3_ID=$(echo $USER3_RESPONSE | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 3 ID: $USER3_ID"

curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER3_ID\"}" | jq '.'
echo ""

# Test 8: Get user registrations
echo "8. Getting registrations for first user..."
curl -s -X GET "$API_URL/users/$USER_ID/registrations" | jq '.'
echo ""

# Test 9: Unregister first user (should promote waitlisted user)
echo "9. Unregistering first user (should promote user from waitlist)..."
curl -s -X DELETE "$API_URL/events/$EVENT_ID/register/$USER_ID" | jq '.'
echo ""

# Test 10: Check third user's registrations (should now be registered)
echo "10. Checking third user's registrations (should be promoted)..."
curl -s -X GET "$API_URL/users/$USER3_ID/registrations" | jq '.'
echo ""

# Test 11: Get event details to see updated counts
echo "11. Getting event details to see updated counts..."
curl -s -X GET "$API_URL/events/$EVENT_ID" | jq '.'
echo ""

echo "=========================================="
echo "Testing Complete!"
echo "=========================================="
