import json
import os
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["TABLE_NAME"]
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        print(f"Received message: {body}")

        if body.get("force_error") is True:
            print("Controlled error triggered")
            raise Exception("Controlled failure for DLQ test")

        item_id = body["id"]
        name = body["name"]
        status = body["status"]
        now = datetime.now(timezone.utc).isoformat()

        item = {
            "PK": f"ITEM#{item_id}",
            "SK": f"META#{now}",
            "itemId": item_id,
            "name": name,
            "status": status,
            "createdAt": now,
            "source": "TP10"
        }

        table.put_item(Item=item)
        print(f"Item stored in DynamoDB: {item_id}")

    return {"status": "ok"}