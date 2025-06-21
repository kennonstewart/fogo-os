#!/bin/bash

set -e

AWS_REGION="us-east-2"
ACCOUNT_ID="865117862950"
ROLE_NAME="firehouse_lambda_exec"
BUCKET_NAME="firehouse-frame-archive"
TABLE_NAME="verification_flags"

echo "🔻 Deleting S3 bucket: $BUCKET_NAME..."
aws s3 rb s3://$BUCKET_NAME --force

echo "Deleting Lambda function: firehouse_frame..."
aws lambda delete-function --function-name firehouse_frame_processor --region $AWS_REGION

echo "🔻 Deleting DynamoDB table: $TABLE_NAME..."
aws dynamodb delete-table --table-name $TABLE_NAME --region $AWS_REGION

echo "🔎 Detaching policies from IAM role: $ROLE_NAME..."
ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE_NAME \
  --query 'AttachedPolicies[].PolicyArn' --output text)

for POLICY_ARN in $ATTACHED_POLICIES; do
  echo "  🔸 Detaching $POLICY_ARN"
  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
done

echo "🔻 Deleting IAM role: $ROLE_NAME..."
aws iam delete-role --role-name $ROLE_NAME

echo "🔎 Finding API Gateway named 'firehouse-api'..."
API_IDS=$(aws apigatewayv2 get-apis --region $AWS_REGION \
  --query "Items[?Name=='firehouse-api'].ApiId" --output text)

if [ -z "$API_IDS" ]; then
  echo "✅ No API Gateway named 'firehouse-api' found."
else
  for API_ID in $API_IDS; do
    echo "🔻 Deleting API Gateway ID: $API_ID..."
    aws apigatewayv2 delete-api --api-id $API_ID --region $AWS_REGION
  done
fi

echo "✅ All specified resources have been deleted."