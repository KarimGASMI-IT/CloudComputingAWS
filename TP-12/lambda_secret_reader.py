import boto3
import os
import json

def lambda_handler(event, context):
    secret_name = os.environ["SECRET_NAME"]

    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)

    secret = json.loads(response["SecretString"])

    print("Secret récupéré au runtime sans exposition du contenu sensible")
    print(f"Username lu depuis Secrets Manager: {secret.get('username')}")

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Secret récupéré avec succès au runtime"
        })
    }