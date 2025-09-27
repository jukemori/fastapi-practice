# AWS Cloud Services: Deploying Applications to the Cloud

## ☁️ What is AWS?

**Amazon Web Services (AWS)** is like **renting a massive, professional data center** where you can:

- **Run your applications** on powerful servers without buying hardware
- **Store data** safely with automatic backups and global distribution
- **Scale instantly** from 1 user to 1 million users
- **Pay only for what you use** - no upfront costs
- **Access enterprise-grade security** that would cost millions to build yourself

Think of it as **moving from your home kitchen to a professional restaurant kitchen** - all the equipment, infrastructure, and expertise you need, available on-demand.

## 🏗️ Core AWS Concepts

### 1. **Regions & Availability Zones**
```
AWS Global Infrastructure:
├── Regions (Geographic locations)
│   ├── us-east-1 (N. Virginia) - Most services first
│   ├── us-west-2 (Oregon) - Great for West Coast
│   ├── eu-west-1 (Ireland) - European users
│   └── ap-southeast-1 (Singapore) - Asian users
│
├── Availability Zones (Data centers within regions)
│   ├── us-east-1a (Physical data center)
│   ├── us-east-1b (Different building/power/network)
│   └── us-east-1c (Independent infrastructure)
│
└── Edge Locations (CDN nodes worldwide)
    ├── CloudFront cache points
    └── Faster content delivery
```

### 2. **Service Categories**
```
AWS Services for Our Todo App:
├── Compute
│   ├── EC2 (Virtual servers)
│   ├── ECS (Container orchestration)
│   └── Lambda (Serverless functions)
├── Storage
│   ├── S3 (Object storage)
│   ├── EBS (Block storage for EC2)
│   └── EFS (Network file system)
├── Database
│   ├── RDS (Managed PostgreSQL)
│   ├── ElastiCache (Redis/Memcached)
│   └── Neptune (Graph database)
├── Networking
│   ├── VPC (Virtual network)
│   ├── ALB (Load balancer)
│   └── Route 53 (DNS)
└── Security
    ├── IAM (Identity management)
    ├── CloudTrail (Audit logs)
    └── WAF (Web application firewall)
```

## 🚀 Deploying Our Todo App to AWS

### Architecture Overview:
```
Internet
    ↓
Application Load Balancer (ALB)
    ↓
┌─────────────────────────────────────┐
│              ECS Cluster            │
├─────────────────┬───────────────────┤
│  Frontend       │    Backend        │
│  (Next.js)      │    (FastAPI)      │
│  ECS Service    │    ECS Service    │
└─────────────────┴───────────────────┘
    ↓                   ↓
┌─────────────────┬───────────────────┐
│  RDS PostgreSQL │    Neptune Neo4j  │
│  (Multi-AZ)     │    (Graph DB)     │
└─────────────────┴───────────────────┘
```

### 1. **VPC (Virtual Private Cloud) Setup**
```yaml
# CloudFormation template for VPC
Resources:
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: TodoApp-VPC

  # Public subnets (for load balancer)
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.1.0/24
      MapPublicIpOnLaunch: true

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.2.0/24
      MapPublicIpOnLaunch: true

  # Private subnets (for applications and databases)
  PrivateSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [0, !GetAZs '']
      CidrBlock: 10.0.10.0/24

  PrivateSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      AvailabilityZone: !Select [1, !GetAZs '']
      CidrBlock: 10.0.11.0/24
```

### 2. **RDS PostgreSQL Setup**
```yaml
# Managed PostgreSQL database
DBSubnetGroup:
  Type: AWS::RDS::DBSubnetGroup
  Properties:
    DBSubnetGroupDescription: Subnet group for RDS database
    SubnetIds:
      - !Ref PrivateSubnet1
      - !Ref PrivateSubnet2

PostgreSQLDB:
  Type: AWS::RDS::DBInstance
  Properties:
    DBInstanceIdentifier: todoapp-postgres
    DBInstanceClass: db.t3.micro  # Free tier eligible
    Engine: postgres
    EngineVersion: '16.1'
    MasterUsername: postgres
    MasterUserPassword: !Ref DBPassword  # From parameter
    AllocatedStorage: 20
    StorageType: gp2
    VPCSecurityGroups:
      - !Ref DatabaseSecurityGroup
    DBSubnetGroupName: !Ref DBSubnetGroup
    MultiAZ: true  # High availability
    BackupRetentionPeriod: 7
    PreferredBackupWindow: "03:00-04:00"
    PreferredMaintenanceWindow: "Sun:04:00-Sun:05:00"
    DeletionProtection: true
```

### 3. **ECS (Elastic Container Service) Setup**
```yaml
# ECS Cluster
ECSCluster:
  Type: AWS::ECS::Cluster
  Properties:
    ClusterName: todoapp-cluster
    CapacityProviders:
      - FARGATE
      - FARGATE_SPOT
    DefaultCapacityProviderStrategy:
      - CapacityProvider: FARGATE
        Weight: 1

# Task Definition for Backend
BackendTaskDefinition:
  Type: AWS::ECS::TaskDefinition
  Properties:
    Family: todoapp-backend
    Cpu: 256  # 0.25 vCPU
    Memory: 512  # 0.5 GB
    NetworkMode: awsvpc
    RequiresCompatibilities:
      - FARGATE
    ExecutionRoleArn: !Ref ECSExecutionRole
    TaskRoleArn: !Ref ECSTaskRole
    ContainerDefinitions:
      - Name: backend
        Image: !Sub ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/todoapp-backend:latest
        PortMappings:
          - ContainerPort: 8000
        Environment:
          - Name: DATABASE_URL
            Value: !Sub 
              - postgresql://postgres:${DBPassword}@${DBEndpoint}:5432/todoapp
              - DBEndpoint: !GetAtt PostgreSQLDB.Endpoint.Address
        LogConfiguration:
          LogDriver: awslogs
          Options:
            awslogs-group: !Ref BackendLogGroup
            awslogs-region: !Ref AWS::Region
            awslogs-stream-prefix: backend
```

### 4. **Application Load Balancer**
```yaml
ApplicationLoadBalancer:
  Type: AWS::ElasticLoadBalancingV2::LoadBalancer
  Properties:
    Name: todoapp-alb
    Scheme: internet-facing
    Type: application
    Subnets:
      - !Ref PublicSubnet1
      - !Ref PublicSubnet2
    SecurityGroups:
      - !Ref ALBSecurityGroup

# Target groups for backend and frontend
BackendTargetGroup:
  Type: AWS::ElasticLoadBalancingV2::TargetGroup
  Properties:
    Name: todoapp-backend-tg
    Port: 8000
    Protocol: HTTP
    VpcId: !Ref VPC
    TargetType: ip
    HealthCheckPath: /health
    HealthCheckIntervalSeconds: 30
    HealthyThresholdCount: 2
    UnhealthyThresholdCount: 5

# Listener rules
ALBListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref FrontendTargetGroup
    LoadBalancerArn: !Ref ApplicationLoadBalancer
    Port: 80
    Protocol: HTTP

BackendListenerRule:
  Type: AWS::ElasticLoadBalancingV2::ListenerRule
  Properties:
    Actions:
      - Type: forward
        TargetGroupArn: !Ref BackendTargetGroup
    Conditions:
      - Field: path-pattern
        Values: ["/api/*"]
    ListenerArn: !Ref ALBListener
    Priority: 100
```

## 📦 Container Registry (ECR)

### Push Images to ECR:
```bash
# Create ECR repositories
aws ecr create-repository --repository-name todoapp-backend
aws ecr create-repository --repository-name todoapp-frontend

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build and tag images
docker build -t todoapp-backend ./backend
docker tag todoapp-backend:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/todoapp-backend:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/todoapp-backend:latest
```

## 🔐 IAM (Identity and Access Management)

### ECS Execution Role:
```yaml
ECSExecutionRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: ecs-tasks.amazonaws.com
          Action: sts:AssumeRole
    ManagedPolicyArns:
      - arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
    Policies:
      - PolicyName: ECRAccess
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - ecr:GetAuthorizationToken
                - ecr:BatchCheckLayerAvailability
                - ecr:GetDownloadUrlForLayer
                - ecr:BatchGetImage
              Resource: '*'
```

### Application Role (for S3, etc.):
```yaml
ECSTaskRole:
  Type: AWS::IAM::Role
  Properties:
    AssumeRolePolicyDocument:
      Version: '2012-10-17'
      Statement:
        - Effect: Allow
          Principal:
            Service: ecs-tasks.amazonaws.com
          Action: sts:AssumeRole
    Policies:
      - PolicyName: S3Access
        PolicyDocument:
          Version: '2012-10-17'
          Statement:
            - Effect: Allow
              Action:
                - s3:GetObject
                - s3:PutObject
                - s3:DeleteObject
              Resource: 
                - !Sub "${TodoAppBucket}/*"
            - Effect: Allow
              Action:
                - s3:ListBucket
              Resource: !Ref TodoAppBucket
```

## 📊 Monitoring & Logging

### CloudWatch Setup:
```yaml
# Log groups
BackendLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /ecs/todoapp-backend
    RetentionInDays: 30

FrontendLogGroup:
  Type: AWS::Logs::LogGroup
  Properties:
    LogGroupName: /ecs/todoapp-frontend
    RetentionInDays: 30

# CloudWatch Alarms
HighCPUAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: TodoApp-HighCPU
    AlarmDescription: CPU utilization is too high
    MetricName: CPUUtilization
    Namespace: AWS/ECS
    Statistic: Average
    Period: 300
    EvaluationPeriods: 2
    Threshold: 80
    ComparisonOperator: GreaterThanThreshold
    Dimensions:
      - Name: ServiceName
        Value: !Ref BackendService
      - Name: ClusterName
        Value: !Ref ECSCluster
    AlarmActions:
      - !Ref SNSTopicArn  # Send notification
```

### Application Performance Monitoring:
```python
# In your FastAPI app
import boto3
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

# X-Ray tracing
xray_recorder.configure(
    context_missing='LOG_ERROR',
    plugins=('EC2Plugin', 'ECSPlugin'),
    daemon_address='127.0.0.1:2000'
)

# Custom metrics
cloudwatch = boto3.client('cloudwatch')

@app.post("/todos")
async def create_todo(todo: TodoCreate):
    start_time = time.time()
    
    try:
        # Your todo creation logic
        result = crud.create_todo(db, todo)
        
        # Log success metric
        cloudwatch.put_metric_data(
            Namespace='TodoApp',
            MetricData=[
                {
                    'MetricName': 'TodosCreated',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        
        return result
    except Exception as e:
        # Log error metric
        cloudwatch.put_metric_data(
            Namespace='TodoApp',
            MetricData=[
                {
                    'MetricName': 'TodoCreationErrors',
                    'Value': 1,
                    'Unit': 'Count'
                }
            ]
        )
        raise
    finally:
        # Log response time
        response_time = time.time() - start_time
        cloudwatch.put_metric_data(
            Namespace='TodoApp',
            MetricData=[
                {
                    'MetricName': 'TodoCreationTime',
                    'Value': response_time * 1000,
                    'Unit': 'Milliseconds'
                }
            ]
        )
```

## 🔒 Security Best Practices

### 1. **Network Security**
```yaml
# Security groups (firewall rules)
DatabaseSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for RDS database
    VpcId: !Ref VPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 5432
        ToPort: 5432
        SourceSecurityGroupId: !Ref ApplicationSecurityGroup  # Only from app

ApplicationSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for ECS tasks
    VpcId: !Ref VPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 8000
        ToPort: 8000
        SourceSecurityGroupId: !Ref ALBSecurityGroup  # Only from load balancer

ALBSecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Security group for Application Load Balancer
    VpcId: !Ref VPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0  # Internet access
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        CidrIp: 0.0.0.0/0  # HTTPS
```

### 2. **Secrets Management**
```yaml
# AWS Secrets Manager
DatabaseSecret:
  Type: AWS::SecretsManager::Secret
  Properties:
    Name: todoapp/database/credentials
    Description: Database credentials for Todo App
    GenerateSecretString:
      SecretStringTemplate: '{"username": "postgres"}'
      GenerateStringKey: 'password'
      PasswordLength: 16
      ExcludeCharacters: '"@/\'

# In ECS task definition
Environment:
  - Name: DATABASE_URL
    ValueFrom: !Ref DatabaseSecret
```

### 3. **SSL/TLS Certificate**
```yaml
# ACM Certificate
SSLCertificate:
  Type: AWS::CertificateManager::Certificate
  Properties:
    DomainName: todoapp.example.com
    SubjectAlternativeNames:
      - api.todoapp.example.com
    ValidationMethod: DNS
    DomainValidationOptions:
      - DomainName: todoapp.example.com
        HostedZoneId: !Ref HostedZone

# HTTPS Listener
HTTPSListener:
  Type: AWS::ElasticLoadBalancingV2::Listener
  Properties:
    DefaultActions:
      - Type: forward
        TargetGroupArn: !Ref FrontendTargetGroup
    LoadBalancerArn: !Ref ApplicationLoadBalancer
    Port: 443
    Protocol: HTTPS
    Certificates:
      - CertificateArn: !Ref SSLCertificate
```

## 📈 Auto Scaling

### ECS Service Auto Scaling:
```yaml
# Scalable target
ScalableTarget:
  Type: AWS::ApplicationAutoScaling::ScalableTarget
  Properties:
    MaxCapacity: 10
    MinCapacity: 2
    ResourceId: !Sub service/${ECSCluster}/${BackendService}
    RoleARN: !Sub arn:aws:iam::${AWS::AccountId}:role/application-autoscaling-ecs-service
    ScalableDimension: ecs:service:DesiredCount
    ServiceNamespace: ecs

# Scaling policy
ScalingPolicy:
  Type: AWS::ApplicationAutoScaling::ScalingPolicy
  Properties:
    PolicyName: todoapp-backend-scaling-policy
    PolicyType: TargetTrackingScaling
    ScalingTargetId: !Ref ScalableTarget
    TargetTrackingScalingPolicyConfiguration:
      PredefinedMetricSpecification:
        PredefinedMetricType: ECSServiceAverageCPUUtilization
      TargetValue: 70.0  # Target 70% CPU utilization
      ScaleOutCooldown: 300
      ScaleInCooldown: 300
```

## 💰 Cost Optimization

### 1. **Instance Types**
```yaml
# Use appropriate instance sizes
TaskDefinition:
  Properties:
    Cpu: 256    # Start small (0.25 vCPU)
    Memory: 512 # 0.5 GB RAM

# Use Spot instances for non-critical workloads
CapacityProviders:
  - FARGATE_SPOT  # Up to 70% savings
```

### 2. **Resource Scheduling**
```python
# Auto-stop non-production environments
import boto3

def lambda_handler(event, context):
    ecs = boto3.client('ecs')
    
    # Scale down staging environment at night
    if event['environment'] == 'staging':
        ecs.update_service(
            cluster='staging-cluster',
            service='todoapp-backend',
            desiredCount=0  # Stop all tasks
        )
```

### 3. **Cost Monitoring**
```yaml
# Budget alerts
TodoAppBudget:
  Type: AWS::Budgets::Budget
  Properties:
    Budget:
      BudgetName: TodoApp-Monthly-Budget
      BudgetLimit:
        Amount: 50  # $50/month
        Unit: USD
      TimeUnit: MONTHLY
      BudgetType: COST
    NotificationsWithSubscribers:
      - Notification:
          NotificationType: ACTUAL
          ComparisonOperator: GREATER_THAN
          Threshold: 80  # Alert at 80% of budget
        Subscribers:
          - SubscriptionType: EMAIL
            Address: admin@example.com
```

## 🚀 Deployment Pipeline

### GitHub Actions for AWS Deployment:
```yaml
# .github/workflows/deploy.yml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and push backend image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: todoapp-backend
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG ./backend
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

      - name: Deploy to ECS
        env:
          ECS_CLUSTER: todoapp-cluster
          ECS_SERVICE: todoapp-backend-service
          ECS_TASK_DEFINITION: todoapp-backend
        run: |
          # Update task definition with new image
          aws ecs update-service \
            --cluster $ECS_CLUSTER \
            --service $ECS_SERVICE \
            --force-new-deployment
```

## 🌍 Global Deployment

### Multi-Region Setup:
```yaml
# Primary region (us-east-1)
PrimaryRegionStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: ./todoapp-infrastructure.yml
    Parameters:
      Environment: production
      Region: us-east-1

# Secondary region (eu-west-1)  
SecondaryRegionStack:
  Type: AWS::CloudFormation::Stack
  Properties:
    TemplateURL: ./todoapp-infrastructure.yml
    Parameters:
      Environment: production
      Region: eu-west-1

# Route 53 health checks and failover
Route53HealthCheck:
  Type: AWS::Route53::HealthCheck
  Properties:
    Type: HTTPS
    ResourcePath: /health
    FullyQualifiedDomainName: !GetAtt ApplicationLoadBalancer.DNSName
    RequestInterval: 30
    FailureThreshold: 3
```

## 🎯 Production Checklist

### Pre-Launch:
```
✅ SSL certificates configured
✅ Database backups enabled
✅ Monitoring and alerting set up
✅ Security groups properly configured
✅ Auto-scaling policies tested
✅ Load testing completed
✅ Disaster recovery plan documented
```

### Post-Launch:
```
✅ Monitor CloudWatch dashboards
✅ Check application logs regularly
✅ Review cost optimization weekly
✅ Update security patches monthly
✅ Test backup restoration quarterly
```

## 🎓 Key Takeaways

1. **AWS provides managed services** - focus on your app, not infrastructure
2. **Start small, scale as needed** - avoid over-provisioning initially
3. **Security is paramount** - use VPCs, security groups, and encryption
4. **Monitor everything** - logs, metrics, costs, and performance
5. **Automate deployments** - CI/CD pipelines reduce errors
6. **Plan for disasters** - backups, multi-AZ, and failover strategies
7. **Optimize costs continuously** - monitor usage and right-size resources
8. **Use Infrastructure as Code** - CloudFormation for reproducible deployments

## 🛠️ Practical Exercise

Deploy the todo app to AWS:

### 1. **Set up AWS CLI**:
```bash
# Install AWS CLI
pip install awscli

# Configure credentials
aws configure
# Enter your Access Key ID, Secret Access Key, region (us-east-1), and output format (json)
```

### 2. **Deploy Infrastructure**:
```bash
# Deploy the CloudFormation stack
aws cloudformation create-stack \
  --stack-name todoapp-infrastructure \
  --template-body file://infrastructure.yml \
  --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=DBPassword,ParameterValue=SecurePassword123
```

### 3. **Push Images and Deploy**:
```bash
# Build and push images
./deploy.sh

# Update ECS service
aws ecs update-service \
  --cluster todoapp-cluster \
  --service todoapp-backend \
  --force-new-deployment
```

### 4. **Test Deployment**:
```bash
# Get load balancer URL
ALB_URL=$(aws elbv2 describe-load-balancers \
  --names todoapp-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Test the application
curl https://$ALB_URL/api/health
```

---

**Previous**: [Podman vs Docker](09-podman-vs-docker.md) | **Next**: [Sphinx Documentation](11-sphinx-documentation.md)