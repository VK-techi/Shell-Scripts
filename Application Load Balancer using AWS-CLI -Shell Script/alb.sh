#! /bin/bash

# To declare Array for name of Instances and target group
arr=( Homepage Login Register Profile )

#for loop to create given no of instances and target groups

for i in 1 2 3 4
do
	
#Launch EC2 instance

aws ec2 run-instances --image-id ami-0108d6a82a783b352 --count 1 --intance-type t2.micro \
--key-name myec2keys --subnet-id subnet-73eac83f --security-group-ids 	sg-04d7a618298d4b6b1 \--user-data file://userdata$i.txt --tag-specifications"ResourceType=instance,Tags=[{Key=Name,Value=${arr[$i]}}]" 

#Create target group with name , protocol , heath check interval etc.

	aws elbv2 create-target-group \
    --name TG-${arr[$i]} \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id vpc-78845313 \
    --health-check-interval-seconds 5 \
    --health-check-timeout-seconds 2 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \

done

#Print the Name and ID of Launched instances  for user reference
aws ec2 describe-instance --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value[],InstanceId]" --output table

#Print the Name and ID of created Target Groups  for user reference

aws elbv2 describe-target-groups --query "TargetGroups[*].{Name:TargetGroupName,ID:TargetGroupArn}" --output table

for i in 1 2 3 4
do
           #Taking input from user to attach instance to particular target group 

	echo "Enter ARN of Target Group - ${arr[$i]}"
	read tgarn

	echo "Enter ID of Instance - ${arr[$i]}"
	read ecid
	
            #Attach launched instances to target groups

	aws elbv2 register-targets --target-group-arn $tgarn --targets Id=$ec2id
	echo - "\n -------------------------------------------------------\n"

done

#Print the Name and ID of Available Security Groups  for user reference

aws ec2 describe-security-groups  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" --output table

#Print the Subnet IDs available for user reference 

aws ec2 describe-subnet --query "Subnets[*].{ID:SubnetId}" --output table

 #Taking input from user required for creating load balancer

echo "Enter Subnet ID"
read subnet_id subnet_id1 subnet_id2

echo "Enter Security Group ID"
read sg_id;

#command to create load balancer 

aws elbv2 create-load-balancer --name "ALB"  \
--subnets $subnet_id $subnet_id1 $subnet_id2 --security-groups $sg_id

#Print the Name & ARN of Target groups for user reference

aws elbv2 describe-target-groups --query "TargetGroups[*].{Name:TargetGroupName,ID:TargetGroupArn}" --output table

#Print the Name and ARN of Created Load balancer for user reference

aws elbv2 describe-load-balancers --query "LoadBalancers[*].{Name:LoadBalancerName,ID:LoadBalancerArn}" --output table

ALB_ID=$(aws elbv2 describe-load-balancers --query "LoadBalancers[0].LoadBalancerArn" \
--output text)

ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[0].TargetGroupArn" \
--output text)

#.Creating Listener for Application Load Balancer to Attach default Target Group 
listner_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ID  \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$ARN \
	--query 'Listeners[0].ListnerArn' \
	--output text)

aws elbv2 describe-target-groups --query "TargetGroups[*].{Name:TargetGroupName,ID:TargetGroupArn}" --output table
arr1=( 2 login register profile )

for i in  2 3 4
do 
	echo "Enter ARN of Target Group => [${arr1[$i]}]"
	read tgarn1

#Redirecting The below writtened data into the file =>actions-forward-path.json
cat <<EOF > actions-forward-path.json
[
  {
      "Type": "forward",
      "ForwardConfig": {
          "TargetGroups": [
              {
                  "TargetGroupArn": "$tgarn1"
              }
          ]
      }
  }
]
EOF

#Redirecting The below writtened data into the file =>conditions-path.json
cat <<EOF > conditions-path.json
[
  {
      "Field": "path-pattern",
      "PathPatternConfig": {
          "Values": ["*${arr1[$i]}*"]
      }
  }
]
EOF
#Add remaining Target groups by Adding New Rules:
AWS_ALB_LISTENER_RULE_ARN=$(aws elbv2 create-rule \
    --listener-arn $listner_ARN\
    --priority $i \
    --condition file://conditions-path.json \
    --actions file://action-forward-path.json \
    --query 'Rules[0].RuleArn' \
    --output text)
done
