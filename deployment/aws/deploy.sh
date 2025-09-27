#!/bin/bash

# AWS Deployment Script for Todo App
set -e

# Configuration
AWS_REGION="us-east-1"
ECR_REPO_BACKEND="todo-backend"
ECR_REPO_FRONTEND="todo-frontend"
STACK_NAME="todo-app-stack"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Starting deployment for Todo App..."
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"

# Create ECR repositories if they don't exist
echo "Creating ECR repositories..."

aws ecr describe-repositories --repository-names $ECR_REPO_BACKEND --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $ECR_REPO_BACKEND --region $AWS_REGION

aws ecr describe-repositories --repository-names $ECR_REPO_FRONTEND --region $AWS_REGION 2>/dev/null || \
aws ecr create-repository --repository-name $ECR_REPO_FRONTEND --region $AWS_REGION

# Get ECR login
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push backend image
echo "Building and pushing backend image..."
cd ../../backend
docker build -t $ECR_REPO_BACKEND .
docker tag $ECR_REPO_BACKEND:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest

# Build and push frontend image
echo "Building and pushing frontend image..."
cd ../frontend
docker build -t $ECR_REPO_FRONTEND .
docker tag $ECR_REPO_FRONTEND:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest

# Deploy CloudFormation stack
echo "Deploying CloudFormation stack..."
cd ../deployment/aws

# Get default VPC and subnets
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text --region $AWS_REGION | tr '\t' ',')

aws cloudformation deploy \
  --template-file cloudformation-template.yaml \
  --stack-name $STACK_NAME \
  --parameter-overrides \
    VpcId=$VPC_ID \
    SubnetIds=$SUBNET_IDS \
    ImageUriBackend=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_BACKEND:latest \
    ImageUriFrontend=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_FRONTEND:latest \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_REGION

echo "Deployment completed successfully!"
echo "You can check the ECS service in the AWS Console."