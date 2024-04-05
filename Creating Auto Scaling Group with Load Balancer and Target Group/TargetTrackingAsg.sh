#!/bin/sh

echo "We are going to create a Application Load Balancer through CLI";
echo "We are first going to create aur custom VPC------------";
#VPC Creation
echo "The VPC ID of newly created VPC is:";
aws ec2 create-vpc --cidr-block 172.35.0.0/16 --query Vpc.VpcId --output text

#Subnet Creation
echo "Now we are going to create our own 2 custom Subnets---------------";
echo "Enter The VPC ID from above";
read vpcId;
echo "Enter 1ST CIDR block ";
read cidr;
echo "The Subnet ID of 1st newly created Subnet:";
aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidr --availability-zone us-east-1a --output text

echo "Enter Subnet ID from above";
read subId;

echo "Enter 2nd CIDR Block";
read cidr2;

echo "The Subnet ID of 2nd newly created Subnet:";
aws ec2 create-subnet --vpc-id $vpcId --cidr-block $cidr2 --availability-zone us-east-1f --output text

echo "Enter Subnet ID from above";
read subId1;

#Making 1st VPC and Subnet public using Internet Gateway and Route Table
echo "Making the VPC and Subnet public----------";

echo "Internet Gateway ID of newly created internet gateway";
aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text

echo "Enter Internet Gateway ID";
read igId;

#Attach the internet gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $igId

#Creating Route Table
echo "Route Table ID of newly created Route Table:";
aws ec2 create-route-table --vpc-id $vpcId --query RouteTable.RouteTableId --output text

echo "Enter Route Table ID from above:";
read rId;

#Route all traffic to the internet gateway
aws ec2 create-route --route-table-id $rId --destination-cidr-block 0.0.0.0/0 --gateway-id $igId

#Associate route with the created subnet
aws ec2 associate-route-table --subnet-id $subId --route-table-id $rId

#Map public IP when instance is launched automatically
aws ec2 modify-subnet-attribute --subnet-id $subId --map-public-ip-on-launch

#Making 2nd VPC and Subnet public using Internet Gateway and Route Table
echo "Making the VPC and Subnet public----------";

#Route all traffic to the internet gateway
aws ec2 create-route --route-table-id $rId --destination-cidr-block 0.0.0.0/0 --gateway-id $igId

#Associate route with the created subnet
aws ec2 associate-route-table --subnet-id $subId1 --route-table-id $rId

#Map public IP when instance is launched automatically
aws ec2 modify-subnet-attribute --subnet-id $subId1 --map-public-ip-on-launch

# Creating custom Security Group 
echo "Creating Security Group----------";
echo "Security group ID of newly created Security Group";
aws ec2 create-security-group --group-name "my-secs-grps" --description "my custom security group" --vpc-id $vpcId
echo "Enter Security group ID:";
read sgId;

echo "Adding TCP,SSH,HTTP Protocol as inbound rule--------------";

#Add Rule to security group
aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sgId --protocol icmp --port -1 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sgId --protocol tcp --port 80 --cidr 0.0.0.0/0

#Creating a Target Groups for the Load Balancer
echo "Creating General target group ----------------------------";
echo "ARN for General TG";

aws elbv2 create-target-group \
--name general \
--protocol HTTP \
--port 80 \
--target-type instance \
--vpc-id $vpcId \
--health-check-interval-seconds 5 \
--health-check-timeout-seconds 2 \
--healthy-threshold-count 2 \
--unhealthy-threshold-count 2

echo "Creating Image target group ----------------------------";
echo "ARN for Image TG";

aws elbv2 create-target-group \
--name image \
--protocol HTTP \
--port 80 \
--target-type instance \
--vpc-id $vpcId \
--health-check-interval-seconds 5 \
--health-check-timeout-seconds 2 \
--healthy-threshold-count 2 \
--unhealthy-threshold-count 2

echo "Creating Video target group ----------------------------";
echo "ARN for Video TG";
aws elbv2 create-target-group \
--name video \
--protocol HTTP \
--port 80 \
--target-type instance \
--vpc-id $vpcId \
--health-check-interval-seconds 5 \
--health-check-timeout-seconds 2 \
--healthy-threshold-count 2 \
--unhealthy-threshold-count 2

echo "Enter the ARN of the default Target Group"
read genarn 
echo "Enter ARN of Image Target Group"
read imgarn
echo "Enter ARN of Video Target Group"
read vidarn

#Creating Load Balancer
echo "Creating Load Balancer--------";
echo "ARN of Load Balancer--------";
aws elbv2 create-load-balancer --name bruh \
--subnets $subId $subId1 --security-groups $sgId

echo "Enter ARN number of Load Balancer";
read lbarn;

#Adding listener for Target Group
echo "Adding listener to port 80 by HTTP for General TG------------";
echo "Port 80 Listener ARN:";

aws elbv2 create-listener \
--load-balancer-arn $lbarn \
--protocol HTTP \
--port 80 \
--default-actions Type=forward,TargetGroupArn=$genarn

#Adding Routing Rules-
echo "Adding Rules for Port 80 Listener";
echo "Enter Port 80 Listener ARN:";
read p80arn;

aws elbv2 create-rule --listener-arn $p80arn --priority 3 \
--conditions Field=path-pattern,Values='/images/*' \
--actions Type=forward,TargetGroupArn=$imgarn

aws elbv2 create-rule --listener-arn $p80arn --priority 2 \
--conditions Field=path-pattern,Values='/videos/*' \
--actions Type=forward,TargetGroupArn=$vidarn 

#Creating LAunch Template
echo "Launch Template ID of new created Launch Template-----"

aws ec2 create-launch-template \
--launch-template-name ALBLaunchTemplate \
--version-description WebVersion1 \
--launch-template-data 
'{"NetworkInterfaces":[{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Subne
tId":"subnet-91b79bf7","Groups":["sg0fb1fe868a48ee7ab"],"DeleteOnTermination":true}],"ImageId":"ami0ed9277fb7eb570c9","InstanceType":"t2.micro"}'

echo "Enter Launch Template ID"
read ltId

#Creating Auto Scaling Group
aws autoscaling create-auto-scaling-group \
--auto-scaling-group-name ALBAutoScaling \
--launch-template LaunchTemplateId=$ltId \
--target-group-arns $imgarn \
--target-group-arns $vidarn \
--target-group-arns $genarn \
--health-check-type ELB \
--health-check-grace-period 600 \
--max-size 3 \
--min-size 1 \
--desired-capacity 2 \
--vpc-zone-identifier "subnet-962251a7,subnet-91b79bf7,subnet-6545b929"

#Add Scaling Policy to the Auto Scaling Group
aws autoscaling put-scaling-policy \
--policy-name cpu60-target-tracking-scaling-policy \
--auto-scaling-group-name ALBAutoScaling \
--policy-type TargetTrackingScaling \
--target-tracking-configuration file://config.json

