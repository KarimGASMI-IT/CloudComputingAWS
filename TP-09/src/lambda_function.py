import json
import logging
import os
from urllib.parse import unquote_plus

import boto3

logger = logging.getLogger()
logger.setLevel(os.getenv("LOG_LEVEL", "INFO"))

s3 = boto3.client("s3")

MAX_SIZE_BYTES = int(os.getenv("MAX_SIZE_BYTES", "1048576"))
ALLOWED_EXTENSIONS = {
    ext.strip().lower()
    for ext in os.getenv("ALLOWED_EXTENSIONS", ".txt,.json,.png").split(",")
    if ext.strip()
}
OUTPUT_PREFIX = os.getenv("OUTPUT_PREFIX", "output/")


def log_event(request_id, status, bucket, key, **kwargs):
    payload = {
        "request_id": request_id,
        "status": status,
        "bucket": bucket,
        "key": key,
    }
    payload.update(kwargs)
    logger.info(json.dumps(payload, ensure_ascii=False))


def get_extension(key: str) -> str:
    _, _, suffix = key.rpartition(".")
    return f".{suffix.lower()}" if suffix else ""


def build_output_key(input_key: str) -> str:
    filename = input_key.split("/")[-1]
    return f"{OUTPUT_PREFIX}{filename}.summary.json"


def lambda_handler(event, context):
    records = event.get("Records", [])
    if not records:
      log_event(context.aws_request_id, "ERROR", "-", "-", message="No records in event")
      raise ValueError("No records in event")

    for record in records:
        event_source = record.get("eventSource")
        if event_source != "aws:s3":
            log_event(
                context.aws_request_id,
                "ERROR",
                "-",
                "-",
                message=f"Unsupported event source: {event_source}",
            )
            raise ValueError(f"Unsupported event source: {event_source}")

        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])

        head = s3.head_object(Bucket=bucket, Key=key)
        size = head["ContentLength"]
        content_type = head.get("ContentType", "application/octet-stream")
        extension = get_extension(key)

        if not key.startswith("input/"):
            log_event(
                context.aws_request_id,
                "REJECTED",
                bucket,
                key,
                reason="INVALID_PREFIX",
                size=size,
                content_type=content_type,
            )
            raise ValueError("Invalid prefix")

        if extension not in ALLOWED_EXTENSIONS:
            log_event(
                context.aws_request_id,
                "REJECTED",
                bucket,
                key,
                reason="INVALID_EXTENSION",
                allowed_extensions=sorted(ALLOWED_EXTENSIONS),
                size=size,
                content_type=content_type,
            )
            raise ValueError(f"Invalid extension: {extension}")

        if size > MAX_SIZE_BYTES:
            log_event(
                context.aws_request_id,
                "REJECTED",
                bucket,
                key,
                reason="FILE_TOO_LARGE",
                max_size_bytes=MAX_SIZE_BYTES,
                size=size,
                content_type=content_type,
            )
            raise ValueError(f"File too large: {size}")

        summary = {
            "request_id": context.aws_request_id,
            "status": "ACCEPTED",
            "bucket": bucket,
            "input_key": key,
            "output_key": build_output_key(key),
            "size": size,
            "content_type": content_type,
            "extension": extension,
        }

        s3.put_object(
            Bucket=bucket,
            Key=summary["output_key"],
            Body=json.dumps(summary, ensure_ascii=False, indent=2).encode("utf-8"),
            ContentType="application/json",
        )

        log_event(
            context.aws_request_id,
            "ACCEPTED",
            bucket,
            key,
            output_key=summary["output_key"],
            size=size,
            content_type=content_type,
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Processing complete", "request_id": context.aws_request_id}),
    }
