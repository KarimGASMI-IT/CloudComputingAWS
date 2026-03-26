import json
import os
import boto3

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]

def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

def lambda_handler(event, context):
    try:
        raw_body = event.get("body")
        if raw_body is None:
            return response(400, {"error": "Missing body"})

        body = json.loads(raw_body)

        allowed_keys = {"id", "name", "status", "force_error"}
        required_keys = {"id", "name", "status"}

        if set(body.keys()) - allowed_keys:
            return response(400, {"error": "Unexpected fields in payload"})

        if not required_keys.issubset(body.keys()):
            return response(400, {"error": "Missing required fields"})

        if not isinstance(body["id"], str) or not body["id"].strip():
            return response(400, {"error": "id must be a non-empty string"})

        if not isinstance(body["name"], str) or not body["name"].strip():
            return response(400, {"error": "name must be a non-empty string"})

        if body["status"] not in ["NEW", "PROCESSING", "DONE"]:
            return response(400, {"error": "status must be one of NEW, PROCESSING, DONE"})

        if "force_error" in body and not isinstance(body["force_error"], bool):
            return response(400, {"error": "force_error must be a boolean"})

        sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(body)
        )

        return response(202, {
            "message": "accepted",
            "itemId": body["id"]
        })

    except json.JSONDecodeError:
        return response(400, {"error": "Invalid JSON"})
    except Exception as e:
        print(f"Producer error: {str(e)}")
        return response(500, {"error": "Internal server error"})