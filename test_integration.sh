#!/bin/bash

API_URL="https://i1zeijbu77.execute-api.us-west-2.amazonaws.com/prod"

echo "=========================================="
echo "Integration Test: Events + Registration"
echo "=========================================="
echo ""

# Test 1: Create event without waitlist
echo "1. Creating event WITHOUT waitlist (capacity: 1)..."
EVENT1_RESPONSE=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Small Workshop",
    "description": "Limited capacity workshop",
    "date": "2025-12-20",
    "location": "Room A",
    "capacity": 1,
    "hasWaitlist": false,
    "organizer": "Test Org",
    "status": "active"
  }')
EVENT1_ID=$(echo $EVENT1_RESPONSE | grep -o '"eventId":"[^"]*"' | cut -d'"' -f4)
echo "Event 1 ID: $EVENT1_ID"
echo "$EVENT1_RESPONSE" | jq '.'
echo ""

# Test 2: Create event with waitlist
echo "2. Creating event WITH waitlist (capacity: 2)..."
EVENT2_RESPONSE=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Popular Conference",
    "description": "High demand conference",
    "date": "2025-12-25",
    "location": "Convention Center",
    "capacity": 2,
    "hasWaitlist": true,
    "organizer": "Conference Org",
    "status": "active"
  }')
EVENT2_ID=$(echo $EVENT2_RESPONSE | grep -o '"eventId":"[^"]*"' | cut -d'"' -f4)
echo "Event 2 ID: $EVENT2_ID"
echo "$EVENT2_RESPONSE" | jq '.'
echo ""

# Test 3: Create users
echo "3. Creating 4 test users..."
USER1=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "Alice"}')
USER1_ID=$(echo $USER1 | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 1 (Alice): $USER1_ID"

USER2=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "Bob"}')
USER2_ID=$(echo $USER2 | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 2 (Bob): $USER2_ID"

USER3=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "Charlie"}')
USER3_ID=$(echo $USER3 | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 3 (Charlie): $USER3_ID"

USER4=$(curl -s -X POST "$API_URL/users" -H "Content-Type: application/json" -d '{"name": "Diana"}')
USER4_ID=$(echo $USER4 | grep -o '"userId":"[^"]*"' | cut -d'"' -f4)
echo "User 4 (Diana): $USER4_ID"
echo ""

# Test 4: Register for event without waitlist
echo "4. Testing event WITHOUT waitlist..."
echo "   a) Register Alice (should succeed)..."
curl -s -X POST "$API_URL/events/$EVENT1_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}" | jq '.'
echo ""

echo "   b) Try to register Bob (should fail - no waitlist)..."
curl -s -X POST "$API_URL/events/$EVENT1_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}" | jq '.'
echo ""

echo "   c) Check event status..."
curl -s -X GET "$API_URL/events/$EVENT1_ID" | jq '{eventId, title, capacity, registeredCount, waitlistCount, hasWaitlist}'
echo ""

# Test 5: Register for event with waitlist
echo "5. Testing event WITH waitlist..."
echo "   a) Register Alice (should succeed)..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}" | jq '.'
echo ""

echo "   b) Register Bob (should succeed)..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER2_ID\"}" | jq '.'
echo ""

echo "   c) Register Charlie (should go to waitlist position 1)..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER3_ID\"}" | jq '.'
echo ""

echo "   d) Register Diana (should go to waitlist position 2)..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER4_ID\"}" | jq '.'
echo ""

echo "   e) Check event status..."
curl -s -X GET "$API_URL/events/$EVENT2_ID" | jq '{eventId, title, capacity, registeredCount, waitlistCount, hasWaitlist}'
echo ""

# Test 6: Test duplicate registration
echo "6. Testing duplicate registration prevention..."
echo "   Try to register Alice again (should fail)..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}" | jq '.'
echo ""

# Test 7: Test user registrations listing
echo "7. Checking Alice's registrations (should show 2 events)..."
curl -s -X GET "$API_URL/users/$USER1_ID/registrations" | jq '[.[] | {event: .event.title, status: .registration.status, date: .event.date}]'
echo ""

echo "8. Checking Charlie's registrations (should show waitlisted)..."
curl -s -X GET "$API_URL/users/$USER3_ID/registrations" | jq '[.[] | {event: .event.title, status: .registration.status, waitlistPosition: .registration.waitlistPosition}]'
echo ""

# Test 8: Test unregistration and promotion
echo "9. Testing automatic waitlist promotion..."
echo "   a) Unregister Alice from Event 2..."
UNREGISTER_RESPONSE=$(curl -s -X DELETE "$API_URL/events/$EVENT2_ID/register/$USER1_ID")
echo "$UNREGISTER_RESPONSE" | jq '.'
PROMOTED_USER=$(echo $UNREGISTER_RESPONSE | grep -o '"promotedUser":"[^"]*"' | cut -d'"' -f4)
echo ""

echo "   b) Check event status (should have Charlie promoted)..."
curl -s -X GET "$API_URL/events/$EVENT2_ID" | jq '{eventId, title, capacity, registeredCount, waitlistCount, hasWaitlist}'
echo ""

echo "   c) Check Charlie's registrations (should now be registered)..."
curl -s -X GET "$API_URL/users/$USER3_ID/registrations" | jq '[.[] | {event: .event.title, status: .registration.status, waitlistPosition: .registration.waitlistPosition}]'
echo ""

echo "   d) Check Diana's registrations (should still be waitlisted at position 1)..."
curl -s -X GET "$API_URL/users/$USER4_ID/registrations" | jq '[.[] | {event: .event.title, status: .registration.status, waitlistPosition: .registration.waitlistPosition}]'
echo ""

# Test 9: Test event update integration
echo "10. Testing event update with registration data..."
echo "   a) Update Event 2 title..."
curl -s -X PUT "$API_URL/events/$EVENT2_ID" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Conference Title"}' | jq '{eventId, title, registeredCount, waitlistCount}'
echo ""

# Test 10: List all events
echo "11. Listing all events with registration counts..."
curl -s -X GET "$API_URL/events" | jq '[.[] | {eventId, title, capacity, registeredCount, waitlistCount, hasWaitlist}]'
echo ""

# Test 11: Test invalid UUID
echo "12. Testing validation with invalid UUID..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d '{"userId": "invalid-uuid"}' | jq '.'
echo ""

# Test 12: Test non-existent user
echo "13. Testing registration with non-existent user..."
curl -s -X POST "$API_URL/events/$EVENT2_ID/register" \
  -H "Content-Type: application/json" \
  -d '{"userId": "00000000-0000-0000-0000-000000000000"}' | jq '.'
echo ""

# Test 13: Test non-existent event
echo "14. Testing registration for non-existent event..."
curl -s -X POST "$API_URL/events/00000000-0000-0000-0000-000000000000/register" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": \"$USER1_ID\"}" | jq '.'
echo ""

echo "=========================================="
echo "Integration Test Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "- Event 1 (no waitlist): $EVENT1_ID"
echo "- Event 2 (with waitlist): $EVENT2_ID"
echo "- User 1 (Alice): $USER1_ID"
echo "- User 2 (Bob): $USER2_ID"
echo "- User 3 (Charlie): $USER3_ID (promoted from waitlist)"
echo "- User 4 (Diana): $USER4_ID (still on waitlist)"
