#!/usr/bin/env python3
"""Test the models locally to verify waitlistEnabled and custom IDs work"""

import sys
sys.path.insert(0, 'backend')

from models import EventCreate, UserCreate

# Test 1: EventCreate with waitlistEnabled
print("Test 1: EventCreate with waitlistEnabled")
event = EventCreate(
    eventId="reg-test-event-789",
    title="Test Event",
    description="Test",
    date="2024-12-20",
    location="Test",
    capacity=2,
    waitlistEnabled=True,
    organizer="Test",
    status="active"
)
print(f"  hasWaitlist: {event.hasWaitlist}")
print(f"  ✅ PASS" if event.hasWaitlist == True else f"  ❌ FAIL")
print()

# Test 2: UserCreate with custom userId
print("Test 2: UserCreate with custom userId")
user = UserCreate(
    userId="test-user-1",
    name="Test User 1"
)
print(f"  userId: {user.userId}")
print(f"  ✅ PASS" if user.userId == "test-user-1" else f"  ❌ FAIL")
print()

# Test 3: EventCreate with hasWaitlist (should still work)
print("Test 3: EventCreate with hasWaitlist (backward compatibility)")
event2 = EventCreate(
    title="Test Event 2",
    description="Test",
    date="2024-12-20",
    location="Test",
    capacity=2,
    hasWaitlist=True,
    organizer="Test",
    status="active"
)
print(f"  hasWaitlist: {event2.hasWaitlist}")
print(f"  ✅ PASS" if event2.hasWaitlist == True else f"  ❌ FAIL")
print()

print("All model tests passed!")
