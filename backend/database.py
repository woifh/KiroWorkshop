import boto3
from botocore.exceptions import ClientError
import os
import uuid
from typing import List, Optional
from models import Event, EventCreate, EventUpdate


class DynamoDBClient:
    def __init__(self):
        self.dynamodb = boto3.resource('dynamodb')
        self.table_name = os.getenv('DYNAMODB_TABLE_NAME', 'Events')
        self.table = self.dynamodb.Table(self.table_name)

    def create_event(self, event: EventCreate) -> Event:
        event_id = str(uuid.uuid4())
        item = {
            'eventId': event_id,
            **event.model_dump()
        }
        
        self.table.put_item(Item=item)
        return Event(**item)

    def get_event(self, event_id: str) -> Optional[Event]:
        try:
            response = self.table.get_item(Key={'eventId': event_id})
            if 'Item' in response:
                return Event(**response['Item'])
            return None
        except ClientError:
            return None

    def list_events(self) -> List[Event]:
        try:
            response = self.table.scan()
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
            response = self.table.update_item(
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
            self.table.delete_item(Key={'eventId': event_id})
            return True
        except ClientError:
            return False
