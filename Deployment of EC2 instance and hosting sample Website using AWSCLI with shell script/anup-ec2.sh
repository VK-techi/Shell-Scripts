#!/bin/sh

#Logged in with a user having ec2 access policy attached

#1--------Creation of VPC, Subnets, Internet Gateway, Route tables--------#

echo "Enter CIDR Block for VPC";
read vpc_cidr;

aws ec2 create-vpc --cidr-block $vpc_cidr

#Assigning name tag to vpc
echo "Enter VPC ID";
read vpc_id;
echo "Assign name to VPC";
read vpc_name;
 
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name

#----------Subnet Creation------------#

echo "Enter CIDR-block for subnet";
read subnet_cidr;

aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet_cidr

#----------Internet Gateway Creation---------#

aws ec2 create-internet-gateway

echo "Enter Internet Gateway ID:";
read igw_id;
echo "Assign name to ig";
read igw_name;

aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=$igw_name

#Attach igw to vpc
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id

#Custom route table for VPC
aws ec2 create-route-table --vpc-id $vpc_id

echo "Enter route table id:";
read route_id;
echo "Add nametag to Route table";
read route_name;

aws ec2 create-route --route-table-id $route_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id

aws ec2 create-tags --resources $route_id --tags Key=Name,Value=$route_name

#Attach Route Table to Subnet
echo "Enter Subnet ID: ";
read sub_id;

aws ec2 associate-route-table --subnet-id $sub_id --route-table-id $route_id

#Enable subnet's public IPV4 addressing

aws ec2 modify-subnet-attribute --subnet-id $sub_id --map-public-ip-on-launch

#---------------Creation Of Security Groups, Key Pair, Instance--------------#
echo "Add nametag to Security Group";
read sg_name;

echo "Add Description of Sec. Group";
read sg_desc;

aws ec2 create-security-group --group-name $sg_name --description "$sg_desc" --vpc-id $vpc_id

echo "Enter SG ID";
read sg_id;

#Add nametage to sg
aws ec2 create-tags --resources $sg_id --tags Key=Name,Value=$sg_name

#open ports
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0

#Creation of Key pair
echo "Enter Key name";
read key_name;
echo "Enter AMI id";
read ami_id;
echo "No of Instances: "
read ninstance;
echo "Type Of Instance";
read itype;


aws ec2 create-key-pair --key-name $key_name --query 'keyMaterial' --output text > $key_name.pem

aws ec2 run-instances --image-id resolve:ssm:$ami_id --count $ninstance --instance-type $itype --key-name $key_name --security-group-ids $sg_id --subnet-id $sub_id

echo "Enter instance id: ";
read i_id;
echo "Enter nametag for instance";
read i_name;

#nametag for instance
aws ec2 create-tags --resources $i_id --tags Key=Name,Value=$i_name

#get public ip
aws ec2 describe-instances --instance-ids $i_id --query "Reservations[0].Instances[0].PublicIpAddress"

#________________________________________EC2 Instance Created in Private VPC with Public IP______________________________

#echo "Enter instance user-name";
#read user_name;
#echo "Enter instance public ip";
#read pub_ip;

#chmod 400 $key_name.pem
#ssh -i $key_name.pem ec2-user@$pub_ip -yes
