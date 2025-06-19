#!/bin/bash

set -e

# -------- CONFIGURATION --------
AWS_REGION="us-east-2"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REPO_NAME="firehouse-frame-processor"
ECR_URI="865117862950.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
TAG="latest"
# --------------------------------

echo "🔧 Building Docker image..."
docker build -t ${REPO_NAME} lambda/

echo "🏷  Tagging image as ${ECR_URI}:${TAG}..."
docker tag ${REPO_NAME}:latest ${ECR_URI}:${TAG}

echo "🔐 Authenticating with Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "🚀 Pushing image to ECR..."
docker push ${ECR_URI}:${TAG}

echo "✅ Image pushed successfully: ${ECR_URI}:${TAG}"