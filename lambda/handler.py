# frame_processor_lambda/handler.py
import json
import base64
import boto3
import os
from opencv_python_headless import cv2
import numpy as np
from deepface import DeepFace
from datetime import datetime
from botocore.exceptions import ClientError

s3 = boto3.client("s3")
ddb = boto3.resource("dynamodb")
table_name = os.environ.get("FLAG_TABLE")
bucket_name = os.environ.get("FRAME_BUCKET")
table = ddb.Table(table_name)

def main(event, context):
    try:
        # Decode the base64-encoded body (assuming image/jpeg or similar)
        body = base64.b64decode(event["body"])
        np_arr = np.frombuffer(body, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        # Run DeepFace verification against a reference image
        ref_path = "/tmp/reference_image.jpg"
        s3.download_file(bucket_name, "reference_image.jpg", ref_path)

        # verify the s3 download
        if not os.path.exists(ref_path):
            raise FileNotFoundError(f"Reference image not found at {ref_path}")

        result = DeepFace.verify(img1_path=ref_path, img2=frame, enforce_detection=False)

        print(f"Verification result: {result}")

        # Log result
        is_verified = result.get("verified", False)
        distance = result.get("distance", None)
        timestamp = datetime.utcnow().isoformat()

        if is_verified:
            frame_key = f"matches/frame_{timestamp}.jpg"
            _, encoded_img = cv2.imencode(".jpg", frame)
            s3.put_object(Bucket=bucket_name, Key=frame_key, Body=encoded_img.tobytes())

        # Update flag table (optional)
        table.put_item(Item={
            "session_id": timestamp,
            "verified": is_verified,
            "distance": str(distance)
        })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "verified": is_verified,
                "distance": distance,
                "timestamp": timestamp
            })
        }

    except ClientError as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}