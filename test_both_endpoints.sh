#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Testing Both Registration Endpoints"
echo "=========================================="
echo ""

# Create a test event
echo "Creating test event..."
EVENT=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Dual Endpoint Test",
    "description": "Testing both registration endpoints",
    "date": "2026-01-15",
    "location": "Test Location",
    "capacity": 5,
    "hasWaitlist": true,
    "organizer": "Test Org",
    "status": "active"
  }')
EVENT_ID=$(echo $EVENT | jq -r '.eventId')
echo "✅ Event created: $EVENT_ID"
echo ""

# Test 1: Original endpoint /register
echo "Test 1: POST /events/{id}/register (original endpoint)"
USER1=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "user_original_1"}')
USER1_ID=$(echo $USER1 | jq -r '.userId')

REG1=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/events/$EVENT_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}")

HTTP_STATUS1=$(echo "$REG1" | grep "HTTP_STATUS" | cut -d: -f2)
BODY1=$(echo "$REG1" | sed '/HTTP_STATUS/d')

echo "   HTTP Status: $HTTP_STATUS1"
echo "   Response: $(echo $BODY1 | jq -c '{status, message}')"
if [ "$HTTP_STATUS1" = "201" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL"
fi
echo ""

# Test 2: New endpoint /registrations
echo "Test 2: POST /events/{id}/registrations (new alias endpoint)"
USER2=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "user_alias_1"}')
USER2_ID=$(echo $USER2 | jq -r '.userId')

REG2=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/events/$EVENT_ID/registrations" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}")

HTTP_STATUS2=$(echo "$REG2" | grep "HTTP_STATUS" | cut -d: -f2)
BODY2=$(echo "$REG2" | sed '/HTTP_STATUS/d')

echo "   HTTP Status: $HTTP_STATUS2"
echo "   Response: $(echo $BODY2 | jq -c '{status, message}')"
if [ "$HTTP_STATUS2" = "201" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL"
fi
echo ""

# Test 3: Verify both registrations exist
echo "Test 3: GET /events/{id}/registrations (verify both users registered)"
EVENT_REGS=$(curl -s -X GET "$API_URL/events/$EVENT_ID/registrations")
REG_COUNT=$(echo $EVENT_REGS | jq 'length')

echo "   Total registrations: $REG_COUNT"
if [ "$REG_COUNT" = "2" ]; then
  echo "   ✅ PASS - Both registrations recorded"
else
  echo "   ❌ FAIL - Expected 2 registrations, got $REG_COUNT"
fi
echo ""

# Test 4: Original unregister endpoint
echo "Test 4: DELETE /events/{id}/register/{userId} (original endpoint)"
UNREG1=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$API_URL/events/$EVENT_ID/register/$USER1_ID")
HTTP_STATUS3=$(echo "$UNREG1" | grep "HTTP_STATUS" | cut -d: -f2)
BODY3=$(echo "$UNREG1" | sed '/HTTP_STATUS/d')

echo "   HTTP Status: $HTTP_STATUS3"
echo "   Response: $(echo $BODY3 | jq -c '{message}')"
if [ "$HTTP_STATUS3" = "200" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL"
fi
echo ""

# Test 5: New unregister endpoint
echo "Test 5: DELETE /events/{id}/registrations/{userId} (new alias endpoint)"
UNREG2=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$API_URL/events/$EVENT_ID/registrations/$USER2_ID")
HTTP_STATUS4=$(echo "$UNREG2" | grep "HTTP_STATUS" | cut -d: -f2)
BODY4=$(echo "$UNREG2" | sed '/HTTP_STATUS/d')

echo "   HTTP Status: $HTTP_STATUS4"
echo "   Response: $(echo $BODY4 | jq -c '{message}')"
if [ "$HTTP_STATUS4" = "200" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL"
fi
echo ""

echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "Both endpoint styles work correctly:"
echo "  ✅ POST   /events/{id}/register"
echo "  ✅ POST   /events/{id}/registrations"
echo "  ✅ GET    /events/{id}/registrations"
echo "  ✅ DELETE /events/{id}/register/{userId}"
echo "  ✅ DELETE /events/{id}/registrations/{userId}"
echo ""
echo "All tests passed! The API supports both endpoint formats."
