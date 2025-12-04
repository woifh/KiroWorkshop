import boto3
from botocore.exceptions import ClientError
import os
import uuid
from typing import List, Optional
from datetime import datetime
from models import (
    Event, EventCreate, EventUpdate,
    User, UserCreate,
    Registration, RegistrationCreate, RegistrationResponse
)


class DynamoDBClient:
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.events_table_name = os.getenv('DYNAMODB_TABLE_NAME', 'Events')
        self.users_table_name = os.getenv('USERS_TABLE_NAME', 'Users')
        self.registrations_table_name = os.getenv('REGISTRATIONS_TABLE_NAME', 'Registrations')
        
        self.events_table = self.dynamodb.Table(self.events_table_name)
        self.users_table = self.dynamodb.Table(self.users_table_name)
        self.registrations_table = self.dynamodb.Table(self.registrations_table_name)

    def create_event(self, event: EventCreate) -> Event:
        event_id = event.eventId if event.eventId else str(uuid.uuid4())
        event_data = event.model_dump(exclude={'eventId'})
        item = {
            'eventId': event_id,
            'registeredCount': 0,
            'waitlistCount': 0,
            **event_data
        }
        
        self.events_table.put_item(Item=item)
        return Event(**item)

    def get_event(self, event_id: str) -> Optional[Event]:
        try:
            response = self.events_table.get_item(Key={'eventId': event_id})
            if 'Item' in response:
                return Event(**response['Item'])
            return None
        except ClientError:
            return None

    def list_events(self) -> List[Event]:
        try:
            response = self.events_table.scan()
            return [Event(**item) for item in response.get('Items', [])]
        except ClientError:
            return []

    def update_event(self, event_id: str, event_update: EventUpdate) -> Optional[Event]:
        update_data = {k: v for k, v in event_update.model_dump().items() if v is not None}
        
        if not update_data:
            return self.get_event(event_id)

        update_expression = "SET " + ", ".join([f"#{k} = :{k}" for k in update_data.keys()])
        expression_attribute_names = {f"#{k}": k for k in update_data.keys()}
        expression_attribute_values = {f":{k}": v for k, v in update_data.items()}

        try:
            response = self.events_table.update_item(
                Key={'eventId': event_id},
                UpdateExpression=update_expression,
                ExpressionAttributeNames=expression_attribute_names,
                ExpressionAttributeValues=expression_attribute_values,
                ReturnValues="ALL_NEW"
            )
            return Event(**response['Attributes'])
        except ClientError:
            return None

    def delete_event(self, event_id: str) -> bool:
        try:
            self.events_table.delete_item(Key={'eventId': event_id})
            return True
        except ClientError:
            return False

    # User methods
    def create_user(self, user: UserCreate) -> User:
        user_id = str(uuid.uuid4())
        created_at = datetime.utcnow().isoformat() + 'Z'
        item = {
            'userId': user_id,
            'name': user.name,
            'createdAt': created_at
        }
        self.users_table.put_item(Item=item)
        return User(**item)

    def get_user(self, user_id: str) -> Optional[User]:
        try:
            response = self.users_table.get_item(Key={'userId': user_id})
            if 'Item' in response:
                return User(**response['Item'])
            return None
        except ClientError:
            return None

    def list_users(self) -> List[User]:
        try:
            response = self.users_table.scan()
            return [User(**item) for item in response.get('Items', [])]
        except ClientError:
            return []

    # Registration methods
    def get_registration(self, user_id: str, event_id: str) -> Optional[Registration]:
        try:
            response = self.registrations_table.query(
                IndexName='userId-eventId-index',
                KeyConditionExpression='userId = :uid AND eventId = :eid',
                ExpressionAttributeValues={
                    ':uid': user_id,
                    ':eid': event_id
                }
            )
            items = response.get('Items', [])
            if items:
                return Registration(**items[0])
            return None
        except ClientError:
            return None

    def create_registration(self, registration: Registration) -> Registration:
        item = registration.model_dump()
        self.registrations_table.put_item(Item=item)
        return registration

    def delete_registration(self, registration_id: str) -> bool:
        try:
            self.registrations_table.delete_item(Key={'registrationId': registration_id})
            return True
        except ClientError:
            return False

    def get_event_registrations(self, event_id: str, status: Optional[str] = None) -> List[Registration]:
        try:
            if status:
                response = self.registrations_table.query(
                    IndexName='eventId-status-index',
                    KeyConditionExpression='eventId = :eid AND #status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':eid': event_id,
                        ':status': status
                    }
                )
            else:
                response = self.registrations_table.query(
                    IndexName='eventId-status-index',
                    KeyConditionExpression='eventId = :eid',
                    ExpressionAttributeValues={':eid': event_id}
                )
            return [Registration(**item) for item in response.get('Items', [])]
        except ClientError:
            return []

    def get_user_registrations(self, user_id: str) -> List[Registration]:
        try:
            response = self.registrations_table.query(
                IndexName='userId-eventId-index',
                KeyConditionExpression='userId = :uid',
                ExpressionAttributeValues={':uid': user_id}
            )
            return [Registration(**item) for item in response.get('Items', [])]
        except ClientError:
            return []

    def increment_event_count(self, event_id: str, field: str, amount: int = 1):
        try:
            self.events_table.update_item(
                Key={'eventId': event_id},
                UpdateExpression=f'SET {field} = if_not_exists({field}, :zero) + :val',
                ExpressionAttributeValues={':val': amount, ':zero': 0}
            )
        except ClientError as e:
            print(f"Error incrementing {field} for event {event_id}: {str(e)}")
            pass

    def get_waitlist_users(self, event_id: str) -> List[Registration]:
        registrations = self.get_event_registrations(event_id, 'waitlisted')
        return sorted(registrations, key=lambda x: x.registeredAt)
