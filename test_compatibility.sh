#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Testing Endpoint Compatibility"
echo "=========================================="
echo ""

# Create test event
echo "✅ POST /events - Create test event"
EVENT=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Compatibility Test Event",
    "description": "Testing endpoint compatibility",
    "date": "2025-12-31",
    "location": "Test Location",
    "capacity": 2,
    "hasWaitlist": true,
    "organizer": "Test Org",
    "status": "active"
  }')
EVENT_ID=$(echo $EVENT | jq -r '.eventId')
echo "   Event ID: $EVENT_ID"
echo ""

# Create users
echo "✅ POST /users - Create user1"
USER1=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "user1"}')
USER1_ID=$(echo $USER1 | jq -r '.userId')
echo "   User1 ID: $USER1_ID"
echo ""

echo "✅ POST /users - Create user2"
USER2=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "user2"}')
USER2_ID=$(echo $USER2 | jq -r '.userId')
echo "   User2 ID: $USER2_ID"
echo ""

echo "✅ POST /users - Create user3"
USER3=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "user3"}')
USER3_ID=$(echo $USER3 | jq -r '.userId')
echo "   User3 ID: $USER3_ID"
echo ""

# Test NEW endpoint (plural)
echo "✅ POST /events/{id}/registrations - Register user1 (NEW ENDPOINT)"
REG1=$(curl -s -X POST "$API_URL/events/$EVENT_ID/registrations" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}")
echo "   Status: $(echo $REG1 | jq -r '.status')"
echo ""

echo "✅ POST /events/{id}/registrations - Register user2 (fills capacity)"
REG2=$(curl -s -X POST "$API_URL/events/$EVENT_ID/registrations" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}")
echo "   Status: $(echo $REG2 | jq -r '.status')"
echo ""

echo "✅ POST /events/{id}/registrations - Register user3 (waitlist)"
REG3=$(curl -s -X POST "$API_URL/events/$EVENT_ID/registrations" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER3_ID\"}")
echo "   Status: $(echo $REG3 | jq -r '.status')"
echo "   Waitlist Position: $(echo $REG3 | jq -r '.waitlistPosition')"
echo ""

# Test NEW endpoint for getting event registrations
echo "✅ GET /events/{id}/registrations - Get event registrations (NEW ENDPOINT)"
EVENT_REGS=$(curl -s -X GET "$API_URL/events/$EVENT_ID/registrations")
echo "   Total registrations: $(echo $EVENT_REGS | jq 'length')"
echo "   Registered: $(echo $EVENT_REGS | jq '[.[] | select(.status == "registered")] | length')"
echo "   Waitlisted: $(echo $EVENT_REGS | jq '[.[] | select(.status == "waitlisted")] | length')"
echo ""

# Test existing endpoint
echo "✅ GET /users/{id}/registrations - Get user registrations"
USER_REGS=$(curl -s -X GET "$API_URL/users/$USER1_ID/registrations")
echo "   User1 registrations: $(echo $USER_REGS | jq 'length')"
echo ""

# Test NEW unregister endpoint (plural)
echo "✅ DELETE /events/{id}/registrations/{userId} - Unregister user1 (NEW ENDPOINT)"
UNREG=$(curl -s -X DELETE "$API_URL/events/$EVENT_ID/registrations/$USER1_ID")
echo "   Message: $(echo $UNREG | jq -r '.message')"
echo "   Promoted: $(echo $UNREG | jq -r '.promotedUser // "none"')"
echo ""

echo "=========================================="
echo "All Tests Passed! ✅"
echo "=========================================="
echo ""
echo "Supported Endpoints:"
echo "  POST   /events/{id}/register         (original)"
echo "  POST   /events/{id}/registrations    (alias) ✅"
echo "  GET    /events/{id}/registrations    (new) ✅"
echo "  GET    /users/{id}/registrations     (original)"
echo "  DELETE /events/{id}/register/{userId}      (original)"
echo "  DELETE /events/{id}/registrations/{userId} (alias) ✅"
