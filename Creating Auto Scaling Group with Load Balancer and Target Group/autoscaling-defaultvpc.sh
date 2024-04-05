#!/bin/bash
echo "Creating Launch Template "
echo "Launch Template Name :"
read ltname
aws ec2 describe-security-groups  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" --output table

echo "Security Groups Id :"
read sg_id

lt_id=$(aws ec2 create-launch-template \
    --launch-template-name $ltname \
    --launch-template-data '{
    "ImageId": "ami-052cef05d01020f1d",
    "InstanceType": "t2.micro",
     "SecurityGroupIds": [''"'$sg_id'"''],
    "TagSpecifications": [{
        "ResourceType": "instance",
        "Tags": [{
            "Key":"Name",
            "Value":"webserver"
        }]
    }],
    
  "UserData": "IyEvYmluL3NoDQpzdWRvIHN1DQp5dW0gaW5zdGFsbCBodHRwZCAteQ0Kc2VydmljZSAgaHR0cGQgc3RhcnQNCm1rZGlyIC92YXIvd3d3L2h0bWwvRWxlY3Ryb25pYw0KbWtkaXIgL3Zhci93d3cvaHRtbC9GYXNoaW9uDQplY2hvICI8aDE+SW5zaWRlIFByaW1lIEluc3RhbmNlICQoaG9zdG5hbWUgLWYpPC9oMT4iID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sDQplY2hvICI8aDE+SW5zaWRlIEVsZWN0cm9uaWMgSW5zdGFuY2UgaW5zaWRlIEVsZWN0cm9uaWMgZGlyZWN0b3J5ICQoaG9zdG5hbWUgLWYpPC9oMT4iID4gL3Zhci93d3cvaHRtbC9FbGVjdHJvbmljL2luZGV4Lmh0bWwNCmVjaG8gIjxoMT5JbnNpZGUgRmFzaGlvbiBJbnN0YW5jZSBpbnNpZGUgRmFzaGlvbiBkaXJlY3RvcnkgJChob3N0bmFtZSAtZik8L2gxPiIgPiAvdmFyL3d3dy9odG1sL0Zhc2hpb24vaW5kZXguaHRtbA==" 
}' --query "LaunchTemplate[0].LaunchTemplateId" --output text)



# To declare static Array
arr=(1 Prime Electronic Fashion)

# Creating 3 Target Groups
for i in 1 2 3 
do
  
  aws elbv2 create-target-group \
    --name TG-${arr[$i]} \
    --protocol HTTP \
    --port 80 \
    --target-type instance \
    --vpc-id vpc-949bbafc \
    --health-check-interval-seconds 5 \
    --health-check-timeout-seconds 2 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 2 \

done


aws ec2 describe-security-groups  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" --output table
aws ec2 describe-subnets --query "Subnets[*].{ID:SubnetId}" --output table

echo "Enter Subnet ID"
read subnet_id subnet_id1 subnet_id2

echo "Security Groups Id :"
read sg_id

# Creating Loadbalancer 
aws elbv2 create-load-balancer --name "ALB"  \
--subnets $subnet_id $subnet_id1 $subnet_id2 --security-groups $sg_id



#Create Default listener for Load balancer
ALB_ID=$(aws elbv2 describe-load-balancers --query "LoadBalancers[0].LoadBalancerArn" \
--output text)

ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[0].TargetGroupArn" \
--output text)


listner_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ID  \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$ARN \
  --query 'Listeners[0].ListenerArn' \
  --output text)

aws elbv2 describe-target-groups --query "TargetGroups[*].{Name:TargetGroupName,ID:TargetGroupArn}" --output table
arr1=(1 2 Electronic Fashion)



for i in  2 3 
do 
  echo "Enter ARN of Target Group => [${arr1[$i]}]"
  read tgarn1

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

cat <<EOF > conditions-path.json
[
  {
      "Field": "path-pattern",
      "PathPatternConfig": {
          "Values": ["${arr1[$i]}"]
      }
  }
]
EOF
AWS_ALB_LISTENER_RULE_ARN=$(aws elbv2 create-rule \
    --listener-arn $listner_ARN\
    --priority $i \
    --conditions file://conditions-path.json \
    --actions file://actions-forward-path.json \
    --query 'Rules[0].RuleArn' \
    --output text)
done


echo "Enter Subnet ID"
read subnet_id subnet_id1 subnet_id2

for i in 1 2 3
do
echo "Enter Auto Scaling Group Name :"
read name


aws ec2 describe-launch-templates --query "LaunchTemplates[*].{Name :LaunchTemplateName, ID:LaunchTemplateId}" --output table

echo "Enter Launch template Id"
read lt_id

echo "Enter Target Group ARN :"
read tgarn

aws autoscaling create-auto-scaling-group --auto-scaling-group-name $name \
  --launch-template LaunchTemplateId=$lt_id,Version='$Latest' \
  --vpc-zone-identifier " $subnet_id , $subnet_id1 ,$subnet_id2" \
  --target-group-arns $tgarn \
  --max-size 3 --min-size 1 --desired-capacity 2 \
  --health-check-grace-period 120 \
  --health-check-type ELB \

done


