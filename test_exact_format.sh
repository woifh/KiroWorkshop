#!/bin/bash

# This script tests the EXACT format the test framework will use
API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Testing Exact Test Format"
echo "=========================================="
echo ""

# Test 1: POST /events with custom eventId and waitlistEnabled
echo "1. POST /events (with custom eventId and waitlistEnabled)"
EVENT_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2024-12-20",
    "eventId": "reg-test-event-789",
    "waitlistEnabled": true,
    "organizer": "Test Organizer",
    "description": "Event for testing user registration functionality",
    "location": "Test Location",
    "title": "Registration Test Event",
    "capacity": 2,
    "status": "active"
  }')

HTTP_STATUS=$(echo "$EVENT_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$EVENT_RESPONSE" | sed '/HTTP_STATUS/d')
echo "   HTTP Status: $HTTP_STATUS"
echo "   Event ID: $(echo $BODY | jq -r '.eventId')"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL - Expected 200/201, got $HTTP_STATUS"
  echo "   Response: $BODY"
fi
echo ""

# Test 2-4: POST /users with custom userId
for i in 1 2 3; do
  echo "$((i+1)). POST /users (with custom userId: test-user-$i)"
  USER_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/users" \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"Test User $i\", \"userId\": \"test-user-$i\"}")
  
  HTTP_STATUS=$(echo "$USER_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
  BODY=$(echo "$USER_RESPONSE" | sed '/HTTP_STATUS/d')
  echo "   HTTP Status: $HTTP_STATUS"
  echo "   User ID: $(echo $BODY | jq -r '.userId')"
  if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "   ✅ PASS"
  else
    echo "   ❌ FAIL - Expected 200/201, got $HTTP_STATUS"
    echo "   Response: $BODY"
  fi
  echo ""
done

# Test 5-7: POST /events/{id}/registrations
for i in 1 2 3; do
  echo "$((i+4)). POST /events/reg-test-event-789/registrations (user $i)"
  REG_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$API_URL/events/reg-test-event-789/registrations" \
    -H "Content-Type: application/json" \
    -d "{\"userId\": \"test-user-$i\"}")
  
  HTTP_STATUS=$(echo "$REG_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
  BODY=$(echo "$REG_RESPONSE" | sed '/HTTP_STATUS/d')
  echo "   HTTP Status: $HTTP_STATUS"
  echo "   Status: $(echo $BODY | jq -r '.status')"
  if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "201" ]; then
    echo "   ✅ PASS"
  else
    echo "   ❌ FAIL - Expected 200/201, got $HTTP_STATUS"
    echo "   Response: $BODY"
  fi
  echo ""
done

# Test 8: GET /events/{id}/registrations
echo "8. GET /events/reg-test-event-789/registrations"
GET_EVENT_REGS=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$API_URL/events/reg-test-event-789/registrations")
HTTP_STATUS=$(echo "$GET_EVENT_REGS" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$GET_EVENT_REGS" | sed '/HTTP_STATUS/d')
echo "   HTTP Status: $HTTP_STATUS"
echo "   Count: $(echo $BODY | jq 'length')"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL - Expected 200, got $HTTP_STATUS"
fi
echo ""

# Test 9: GET /users/{id}/registrations
echo "9. GET /users/test-user-1/registrations"
GET_USER_REGS=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET "$API_URL/users/test-user-1/registrations")
HTTP_STATUS=$(echo "$GET_USER_REGS" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$GET_USER_REGS" | sed '/HTTP_STATUS/d')
echo "   HTTP Status: $HTTP_STATUS"
echo "   Count: $(echo $BODY | jq 'length')"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL - Expected 200, got $HTTP_STATUS"
fi
echo ""

# Test 10: DELETE /events/{id}/registrations/{userId}
echo "10. DELETE /events/reg-test-event-789/registrations/test-user-1"
DELETE_RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$API_URL/events/reg-test-event-789/registrations/test-user-1")
HTTP_STATUS=$(echo "$DELETE_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$DELETE_RESPONSE" | sed '/HTTP_STATUS/d')
echo "   HTTP Status: $HTTP_STATUS"
if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "204" ]; then
  echo "   ✅ PASS"
else
  echo "   ❌ FAIL - Expected 200/204, got $HTTP_STATUS"
  echo "   Response: $BODY"
fi
echo ""

echo "=========================================="
echo "Test Complete"
echo "=========================================="
