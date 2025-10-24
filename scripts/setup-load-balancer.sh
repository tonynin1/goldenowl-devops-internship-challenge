#!/bin/bash

###############################################################################
# Golden Owl - Load Balancer and Auto Scaling Setup Script
#
# This script automates the creation of:
# - Application Load Balancer (ALB)
# - Target Group with health checks
# - Launch Template
# - Auto Scaling Group (2-5 instances)
# - CloudWatch alarms for auto scaling
#
# Prerequisites:
# - AWS CLI configured
# - Existing EC2 instance with app running
# - VPC with at least 2 public subnets in different AZs
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration - EDIT THESE VALUES
INSTANCE_ID="i-0c5dbc4615d20ed81"           # Your existing EC2 instance ID
AMI_ID="ami-0690ccab4d3e763fa"              # Your AMI ID (already created)
KEY_PAIR_NAME="golden-owl-key"         # Your SSH key pair name
VPC_ID="vpc-0348de8287979ec62"                # Your VPC ID
SUBNET_1="subnet-00c0b832ac5bc8d80"              # Public subnet in AZ 1
SUBNET_2="subnet-0dc9f3821a4b5cef0"              # Public subnet in AZ 2
EC2_SG="sg-08ff8a6f238ed8e14"                # Your EC2 security group ID
DOCKERHUB_USERNAME="tonynin1"    # Your Docker Hub username
AWS_REGION="us-east-1"   # AWS region

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Run 'aws configure' first."
        exit 1
    fi

    print_info "Prerequisites check passed ✓"
}

# Function to validate configuration
validate_config() {
    print_info "Validating configuration..."

    if [ -z "$INSTANCE_ID" ] || [ -z "$AMI_ID" ] || [ -z "$KEY_PAIR_NAME" ] || [ -z "$VPC_ID" ] || \
       [ -z "$SUBNET_1" ] || [ -z "$SUBNET_2" ] || [ -z "$EC2_SG" ] || \
       [ -z "$DOCKERHUB_USERNAME" ]; then
        print_error "Please edit the script and fill in all required configuration values"
        exit 1
    fi

    print_info "Configuration validated ✓"
}

# Function to create AMI from existing instance
create_ami() {
    print_info "Creating AMI from instance $INSTANCE_ID..."

    AMI_NAME="golden-owl-app-$(date +%Y%m%d-%H%M%S)"

    AMI_ID=$(aws ec2 create-image \
        --instance-id "$INSTANCE_ID" \
        --name "$AMI_NAME" \
        --description "Golden Owl app with Docker pre-installed" \
        --no-reboot \
        --region "$AWS_REGION" \
        --output text --query 'ImageId')

    print_info "AMI created: $AMI_ID"
    print_info "Waiting for AMI to be available..."

    aws ec2 wait image-available --image-ids "$AMI_ID" --region "$AWS_REGION"

    print_info "AMI is ready ✓"
}

# Function to create user data script
create_user_data() {
    print_info "Creating user data script..."

    cat > /tmp/user-data.sh << EOF
#!/bin/bash
# Pull and run the latest Docker image
docker pull ${DOCKERHUB_USERNAME}/golden-owl-app:latest
docker stop golden-owl-app || true
docker rm golden-owl-app || true
docker run -d -p 80:3000 --name golden-owl-app --restart unless-stopped \\
  ${DOCKERHUB_USERNAME}/golden-owl-app:latest

# Install CloudWatch agent for better monitoring
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
EOF

    USER_DATA=$(base64 -w 0 /tmp/user-data.sh)
    print_info "User data script created ✓"
}

# Function to create launch template
create_launch_template() {
    print_info "Creating launch template..."

    create_user_data

    cat > /tmp/launch-template.json << EOF
{
  "LaunchTemplateName": "golden-owl-launch-template",
  "VersionDescription": "v1.0",
  "LaunchTemplateData": {
    "ImageId": "${AMI_ID}",
    "InstanceType": "t2.micro",
    "KeyName": "${KEY_PAIR_NAME}",
    "SecurityGroupIds": ["${EC2_SG}"],
    "UserData": "${USER_DATA}",
    "TagSpecifications": [
      {
        "ResourceType": "instance",
        "Tags": [
          {
            "Key": "Name",
            "Value": "golden-owl-app-asg"
          },
          {
            "Key": "Environment",
            "Value": "production"
          },
          {
            "Key": "ManagedBy",
            "Value": "AutoScaling"
          }
        ]
      }
    ],
    "Monitoring": {
      "Enabled": true
    }
  }
}
EOF

    aws ec2 create-launch-template \
        --cli-input-json file:///tmp/launch-template.json \
        --region "$AWS_REGION" > /dev/null

    print_info "Launch template created ✓"
}

# Function to create ALB security group
create_alb_security_group() {
    print_info "Creating security group for ALB..."

    ALB_SG=$(aws ec2 create-security-group \
        --group-name golden-owl-alb-sg \
        --description "Security group for Golden Owl ALB" \
        --vpc-id "$VPC_ID" \
        --region "$AWS_REGION" \
        --output text --query 'GroupId')

    # Allow HTTP traffic
    aws ec2 authorize-security-group-ingress \
        --group-id "$ALB_SG" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" > /dev/null

    print_info "ALB security group created: $ALB_SG ✓"
}

# Function to create Application Load Balancer
create_load_balancer() {
    print_info "Creating Application Load Balancer..."

    ALB_ARN=$(aws elbv2 create-load-balancer \
        --name golden-owl-alb \
        --subnets "$SUBNET_1" "$SUBNET_2" \
        --security-groups "$ALB_SG" \
        --scheme internet-facing \
        --type application \
        --ip-address-type ipv4 \
        --region "$AWS_REGION" \
        --output text --query 'LoadBalancers[0].LoadBalancerArn')

    ALB_DNS=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_ARN" \
        --region "$AWS_REGION" \
        --output text --query 'LoadBalancers[0].DNSName')

    print_info "Load Balancer created ✓"
    print_info "ALB DNS: ${GREEN}http://${ALB_DNS}${NC}"
}

# Function to create target group
create_target_group() {
    print_info "Creating target group..."

    TG_ARN=$(aws elbv2 create-target-group \
        --name golden-owl-tg \
        --protocol HTTP \
        --port 80 \
        --vpc-id "$VPC_ID" \
        --health-check-path / \
        --health-check-interval-seconds 30 \
        --health-check-timeout-seconds 5 \
        --healthy-threshold-count 2 \
        --unhealthy-threshold-count 3 \
        --matcher HttpCode=200 \
        --region "$AWS_REGION" \
        --output text --query 'TargetGroups[0].TargetGroupArn')

    print_info "Target group created ✓"
}

# Function to create ALB listener
create_listener() {
    print_info "Creating ALB listener..."

    aws elbv2 create-listener \
        --load-balancer-arn "$ALB_ARN" \
        --protocol HTTP \
        --port 80 \
        --default-actions Type=forward,TargetGroupArn="$TG_ARN" \
        --region "$AWS_REGION" > /dev/null

    print_info "Listener created ✓"
}

# Function to update EC2 security group
update_ec2_security_group() {
    print_info "Updating EC2 security group to allow traffic from ALB..."

    aws ec2 authorize-security-group-ingress \
        --group-id "$EC2_SG" \
        --protocol tcp \
        --port 80 \
        --source-group "$ALB_SG" \
        --region "$AWS_REGION" 2>/dev/null || print_warning "Rule may already exist"

    print_info "Security group updated ✓"
}

# Function to create Auto Scaling Group
create_auto_scaling_group() {
    print_info "Creating Auto Scaling Group..."

    aws autoscaling create-auto-scaling-group \
        --auto-scaling-group-name golden-owl-asg \
        --launch-template LaunchTemplateName=golden-owl-launch-template,Version='$Latest' \
        --min-size 2 \
        --max-size 5 \
        --desired-capacity 2 \
        --default-cooldown 300 \
        --health-check-type ELB \
        --health-check-grace-period 300 \
        --vpc-zone-identifier "$SUBNET_1,$SUBNET_2" \
        --target-group-arns "$TG_ARN" \
        --region "$AWS_REGION" \
        --tags Key=Name,Value=golden-owl-asg-instance,PropagateAtLaunch=true \
               Key=Environment,Value=production,PropagateAtLaunch=true

    print_info "Auto Scaling Group created ✓"
    print_info "Min: 2, Max: 5, Desired: 2 instances"
}

# Function to create scaling policies
create_scaling_policies() {
    print_info "Creating auto scaling policies..."

    # Scale up policy
    SCALE_UP_ARN=$(aws autoscaling put-scaling-policy \
        --auto-scaling-group-name golden-owl-asg \
        --policy-name scale-up-on-cpu \
        --scaling-adjustment 1 \
        --adjustment-type ChangeInCapacity \
        --cooldown 300 \
        --region "$AWS_REGION" \
        --output text --query 'PolicyARN')

    # CloudWatch alarm for scale up
    aws cloudwatch put-metric-alarm \
        --alarm-name golden-owl-cpu-high \
        --alarm-description "Scale up when CPU exceeds 70%" \
        --metric-name CPUUtilization \
        --namespace AWS/EC2 \
        --statistic Average \
        --period 300 \
        --threshold 70 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions "$SCALE_UP_ARN" \
        --region "$AWS_REGION" \
        --dimensions Name=AutoScalingGroupName,Value=golden-owl-asg

    print_info "Scale-up policy created (CPU > 70%) ✓"

    # Scale down policy
    SCALE_DOWN_ARN=$(aws autoscaling put-scaling-policy \
        --auto-scaling-group-name golden-owl-asg \
        --policy-name scale-down-on-cpu \
        --scaling-adjustment -1 \
        --adjustment-type ChangeInCapacity \
        --cooldown 300 \
        --region "$AWS_REGION" \
        --output text --query 'PolicyARN')

    # CloudWatch alarm for scale down
    aws cloudwatch put-metric-alarm \
        --alarm-name golden-owl-cpu-low \
        --alarm-description "Scale down when CPU below 30%" \
        --metric-name CPUUtilization \
        --namespace AWS/EC2 \
        --statistic Average \
        --period 300 \
        --threshold 30 \
        --comparison-operator LessThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions "$SCALE_DOWN_ARN" \
        --region "$AWS_REGION" \
        --dimensions Name=AutoScalingGroupName,Value=golden-owl-asg

    print_info "Scale-down policy created (CPU < 30%) ✓"
}

# Function to print summary
print_summary() {
    echo ""
    echo "=========================================="
    print_info "Setup Complete! 🎉"
    echo "=========================================="
    echo ""
    echo "Resources Created:"
    echo "  - AMI: $AMI_ID"
    echo "  - Launch Template: golden-owl-launch-template"
    echo "  - Load Balancer: golden-owl-alb"
    echo "  - Target Group: golden-owl-tg"
    echo "  - Auto Scaling Group: golden-owl-asg"
    echo "  - CloudWatch Alarms: golden-owl-cpu-high, golden-owl-cpu-low"
    echo ""
    echo "Configuration:"
    echo "  - Min Instances: 2"
    echo "  - Max Instances: 5"
    echo "  - Scale Up: CPU > 70%"
    echo "  - Scale Down: CPU < 30%"
    echo ""
    echo -e "${GREEN}Application URL:${NC} http://${ALB_DNS}"
    echo ""
    echo "Wait 3-5 minutes for instances to launch and become healthy."
    echo ""
    echo "Test with:"
    echo "  curl http://${ALB_DNS}"
    echo ""
    echo "Monitor:"
    echo "  aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names golden-owl-asg"
    echo "  aws elbv2 describe-target-health --target-group-arn $TG_ARN"
    echo ""
}

# Main execution
main() {
    echo "=========================================="
    echo "Golden Owl - Load Balancer & Auto Scaling Setup"
    echo "=========================================="
    echo ""

    check_prerequisites
    validate_config

    # Skip AMI creation - using existing AMI
    print_info "Using existing AMI: $AMI_ID"

    create_launch_template
    create_alb_security_group
    create_load_balancer
    create_target_group
    create_listener
    update_ec2_security_group
    create_auto_scaling_group
    create_scaling_policies

    print_summary
}

# Run main function
main
