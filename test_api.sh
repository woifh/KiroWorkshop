#!/bin/bash

# Test script for Events API
API_URL="${1:-http://localhost:8000}"

echo "Testing Events API at: $API_URL"
echo ""

# Health check
echo "1. Health Check:"
curl -s "$API_URL/health" | python3 -m json.tool
echo -e "\n"

# Create an event
echo "2. Creating an event:"
EVENT_RESPONSE=$(curl -s -X POST "$API_URL/events" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Tech Conference 2025",
    "description": "Annual technology conference",
    "date": "2025-06-15",
    "location": "San Francisco, CA",
    "capacity": 500,
    "organizer": "Tech Corp",
    "status": "active"
  }')
echo "$EVENT_RESPONSE" | python3 -m json.tool
EVENT_ID=$(echo "$EVENT_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['eventId'])" 2>/dev/null)
echo -e "\n"

# List all events
echo "3. Listing all events:"
curl -s "$API_URL/events" | python3 -m json.tool
echo -e "\n"

if [ ! -z "$EVENT_ID" ]; then
  # Get specific event
  echo "4. Getting event $EVENT_ID:"
  curl -s "$API_URL/events/$EVENT_ID" | python3 -m json.tool
  echo -e "\n"

  # Update event
  echo "5. Updating event $EVENT_ID:"
  curl -s -X PUT "$API_URL/events/$EVENT_ID" \
    -H "Content-Type: application/json" \
    -d '{"status": "completed"}' | python3 -m json.tool
  echo -e "\n"

  # Delete event
  echo "6. Deleting event $EVENT_ID:"
  curl -s -X DELETE "$API_URL/events/$EVENT_ID" -w "\nStatus: %{http_code}\n"
  echo -e "\n"
fi

echo "Testing complete!"
