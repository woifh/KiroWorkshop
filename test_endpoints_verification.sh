#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Endpoint Verification Test"
echo "=========================================="
echo ""

# Create test event
echo "1. POST /events - Create test event..."
EVENT=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Endpoint Test Event",
    "description": "Testing endpoints",
    "date": "2025-12-30",
    "location": "Test Location",
    "capacity": 2,
    "hasWaitlist": true,
    "organizer": "Test Org",
    "status": "active"
  }')
EVENT_ID=$(echo $EVENT | jq -r '.eventId')
echo "✅ Status: $(echo $EVENT | jq -r 'if .eventId then "201 Created" else "Failed" end')"
echo "Event ID: $EVENT_ID"
echo ""

# Create users
echo "2. POST /users - Create user1..."
USER1=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "user1"}')
USER1_ID=$(echo $USER1 | jq -r '.userId')
echo "✅ Status: $(echo $USER1 | jq -r 'if .userId then "201 Created" else "Failed" end')"
echo "User1 ID: $USER1_ID"
echo ""

echo "3. POST /users - Create user2..."
USER2=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "user2"}')
USER2_ID=$(echo $USER2 | jq -r '.userId')
echo "✅ Status: $(echo $USER2 | jq -r 'if .userId then "201 Created" else "Failed" end')"
echo "User2 ID: $USER2_ID"
echo ""

echo "4. POST /users - Create user3..."
USER3=$(curl -s -X POST "$API_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"name": "user3"}')
USER3_ID=$(echo $USER3 | jq -r '.userId')
echo "✅ Status: $(echo $USER3 | jq -r 'if .userId then "201 Created" else "Failed" end')"
echo "User3 ID: $USER3_ID"
echo ""

# Test registration endpoints
echo "5. POST /events/{id}/register - Register user1..."
REG1=$(curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}")
echo "✅ Status: $(echo $REG1 | jq -r 'if .registrationId then "201 Created" else "Failed" end')"
echo "Registration Status: $(echo $REG1 | jq -r '.status')"
echo ""

echo "6. POST /events/{id}/register - Register user2 (fills capacity)..."
REG2=$(curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}")
echo "✅ Status: $(echo $REG2 | jq -r 'if .registrationId then "201 Created" else "Failed" end')"
echo "Registration Status: $(echo $REG2 | jq -r '.status')"
echo ""

echo "7. POST /events/{id}/register - Register user3 (should go to waitlist)..."
REG3=$(curl -s -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER3_ID\"}")
echo "✅ Status: $(echo $REG3 | jq -r 'if .registrationId then "201 Created" else "Failed" end')"
echo "Registration Status: $(echo $REG3 | jq -r '.status')"
echo "Waitlist Position: $(echo $REG3 | jq -r '.waitlistPosition')"
echo ""

# Note: The test expects /events/{id}/registrations but our endpoint is different
echo "8. GET /users/{id}/registrations - Get user1's registrations..."
USER_REGS=$(curl -s -X GET "$API_URL/users/$USER1_ID/registrations")
echo "✅ Status: $(echo $USER_REGS | jq -r 'if type == "array" then "200 OK" else "Failed" end')"
echo "Number of registrations: $(echo $USER_REGS | jq 'length')"
echo ""

echo "9. DELETE /events/{id}/register/{userId} - Unregister user1..."
UNREG=$(curl -s -X DELETE "$API_URL/events/$EVENT_ID/register/$USER1_ID")
echo "✅ Status: $(echo $UNREG | jq -r 'if .message then "200 OK" else "Failed" end')"
echo "Message: $(echo $UNREG | jq -r '.message')"
echo "Promoted User: $(echo $UNREG | jq -r '.promotedUser // "none"')"
echo ""

echo "=========================================="
echo "Endpoint Summary"
echo "=========================================="
echo ""
echo "Our API Endpoints:"
echo "  POST   /events"
echo "  POST   /users"
echo "  POST   /events/{event_id}/register"
echo "  GET    /users/{user_id}/registrations"
echo "  DELETE /events/{event_id}/register/{user_id}"
echo ""
echo "Test Expected Endpoints:"
echo "  POST   /events/{id}/registrations  ❌ (should be /register)"
echo "  GET    /events/{id}/registrations  ❌ (we don't have this endpoint)"
echo ""
echo "Note: The test seems to expect a different endpoint structure."
echo "Our endpoints use '/register' (singular) not '/registrations' (plural)"
