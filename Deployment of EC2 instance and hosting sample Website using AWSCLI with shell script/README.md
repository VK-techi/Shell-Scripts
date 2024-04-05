
# Deployment of EC2 instance and hosting sample Website using AWSCLI

![Visitor Count](https://profile-counter.glitch.me/Anup-Narkhede/count.svg)

## Description

We are going to create an AWS instance without AWS console.

How is that possible ?

Here we want to create a basic infrastructure for a website where there is no access to AWS console.  Initially,  we are creating a VPC  in ap-south-1 region with 1 public subnet. Then the next step is the creation of EC2 instance, which includes selecting an appropriate AMI, Instance type, security groups, key pairs, etc...In this project we are using http as our web-server. I have provided here with a detailed command summary that I have executed in the project.
  
## Architecture Diagram

![App Screenshot](https://demobucketanup.s3.ap-south-1.amazonaws.com/figma+aws.png)

  
## Resources

- VPC
- Subnets
- Internet gateway
- Route table
- Security group
- Key pair
- EC2 instance
  

## Prerequisites for this Project

- AWS CLI on your system
- Need an IAM user access with attached policies for the creation of EC2 instance
- Knowledge to the requirements of Vpc, Ec2, Ebs, IAM

## Installtion of AWS CLI

Innstallation of AWCLI depends on the Operating systems that installed on your system. Please check the following official documentation to install the awscli on your system.

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


## STEP 1 - IAM ROLE Creation

Initially, I have configured an IAM user with the available access key ID and AWS secret key.

```bash
AWS Access Key ID [None]: **************
AWS Secret Access Key [None]: ***********
Default region name [None]: ap-south-1
Default output format [None]: json
```

## STEP 2 - Creation of VPC, Subnets, Internet Gateway, Route tables

Here, I have created a vpc with IP range 172.32.0.0/16

```bash
aws ec2 create-vpc --cidr-block 172.32.0.0/16
```

Output

```bash
{
    "Vpc": {
        "CidrBlock": "172.32.0.0/16",
        "DhcpOptionsId": "dopt-01666969",
        "State": "pending",
        "VpcId": "vpc-0f0d4e8f321404d44",
        "OwnerId": "285450478623",
        "InstanceTenancy": "default",
        "Ipv6CidrBlockAssociationSet": [],
        "CidrBlockAssociationSet": [
            {
                "AssociationId": "vpc-cidr-assoc-03d1d3e42181451fb",
                "CidrBlock": "172.32.0.0/16",
                "CidrBlockState": {
                    "State": "associated"
                }
            }
        ],
        "IsDefault": false
    }
}

```

Assigning name tag for newly created VPC

```bash
aws ec2 create-tags --resources vpc-0f0d4e8f321404d44 --tags Key=Name,Value=AWS-OEA-VPC
```

### Subnet creation

Here we are partitioning the previously created VPC "vpc-0b7c1bfe7fb631fd3" to  subnet.

```bash
aws ec2 create-subnet --vpc-id vpc-0f0d4e8f321404d44 --cidr-block 172.32.64.0/18

```

### Output

```bash
{
    "Subnet": {
        "AvailabilityZone": "ap-south-1b",
        "AvailabilityZoneId": "aps1-az3",
        "AvailableIpAddressCount": 16379,
        "CidrBlock": "172.32.64.0/18",
        "DefaultForAz": false,
        "MapPublicIpOnLaunch": false,
        "State": "available",
        "SubnetId": "subnet-0eb614a78cb9b8051",
        "VpcId": "vpc-0f0d4e8f321404d44",
        "OwnerId": "285450478623",
        "AssignIpv6AddressOnCreation": false,
        "Ipv6CidrBlockAssociationSet": [],
        "SubnetArn": "arn:aws:ec2:ap-south-1:285450478623:subnet/subnet-0eb614a78cb9b8051"
    }
}

```

The next step is the Conversion of Subnet to public

### Creation of Internet Gateway with name tag "igw-oea"

```bash
aws ec2 create-internet-gateway

```

#### output
```bash
{
    "InternetGateway": {
        "Attachments": [],
        "InternetGatewayId": "igw-04d5e1328027833e2",
        "OwnerId": "285450478623",
        "Tags": []
    }
}

```
attach name tag to igw

```bash
aws ec2 create-tags --resources igw-04d5e1328027833e2 --tags Key=Name,Value=igw-oea

```

#### Attached Internet Gateway to VPC "AWS-OEA-VPC" ID: vpc-0f0d4e8f321404d44

```bash
aws ec2 attach-internet-gateway --vpc-id vpc-0f0d4e8f321404d44 --internet-gateway-id igw-04d5e1328027833e2

```

#### Create a Custom Route table "route-oea" for the VPC

```bash
aws ec2 create-route-table --vpc-id vpc-0f0d4e8f321404d44

```
#### output

```bash
{
    "RouteTable": {
        "Associations": [],
        "PropagatingVgws": [],
        "RouteTableId": "rtb-06256b6a38f320c00",
        "Routes": [
            {
                "DestinationCidrBlock": "172.32.0.0/16",
                "GatewayId": "local",
                "Origin": "CreateRouteTable",
                "State": "active"
            }
        ],
        "Tags": [],
        "VpcId": "vpc-0f0d4e8f321404d44",
        "OwnerId": "285450478623"
    }
}

```

Point the route table to the IGW with all traffic (0.0.0.0/0) and nametag to the route table

```bash
aws ec2 create-route --route-table-id rtb-06256b6a38f320c00 --destination-cidr-block 0.0.0.0/0 --gateway-id igw-04d5e1328027833e2

```
```bash
aws ec2 create-tags --resources rtb-06256b6a38f320c00 --tags Key=Name,Value=route-anup
```
#### output

```bash
{
    "Return": true
}

```

Next step - Attaching the route table to subnets so that traffic from that subnet is routed to the internet gateway

Below command - List the subnets under the VPC

```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0f0d4e8f321404d44" --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock}"

```

#### output

```bash
[
    {
        "ID": "subnet-0eb614a78cb9b8051",
        "CIDR": "172.32.64.0/18"
    }
]

```

Update subnet to associate with the custom route table.

```bash
aws ec2 associate-route-table --subnet-id subnet-0eb614a78cb9b8051 --route-table-id rtb-06256b6a38f320c00
```
output

```bash
{
    "AssociationId": "rtbassoc-04506bf6b3e6569c3",
    "AssociationState": {
        "State": "associated"
    }
}

```
Enabling of subnet's public IPV4 addressing behavior so that an instance launched into subnet automatically receives a public IP address.

```bash
aws ec2 modify-subnet-attribute --subnet-id subnet-0eb614a78cb9b8051 --map-public-ip-on-launch
```

## STEP 3 - Creation of security Groups, key pair, Instance

### Creation of security Group

A Security group(Stateful- check inbound rules only, outbound is allow all) is an instance level firewall. Security group is created with open ports 22(SSH),80(HTTP) and 443(HTTPS).

```bash
aws ec2 create-security-group --group-name sgoea --description "security group with ports 80, 20 and 443 are open" --vpc-id vpc-0f0d4e8f321404d44
```

output:

```bash
{
    "GroupId": "sg-038586d6829de9c93"
}
```
Add nametag to security group

```bash
aws ec2 create-tags --resources sg-038586d6829de9c93 --tags Key=Name,Value=sgoea 
```
Next, We are opening port 22 and 80 for inbound connections in security group.

```bash
aws ec2 authorize-security-group-ingress --group-id sg-038586d6829de9c93 --protocol tcp --port 22 --cidr 0.0.0.0/0 
```
### Creation of Key pair

The aws ec2 command stores the public key and outputs the private key for you to save to a file.

The following command creates private key "Key-example" and stores in pem file "Key-example"

```bash
aws ec2 create-key-pair --key-name oeaanup --query 'keyMaterial' --output text > oeaanup.pem

```
### Amazon Machine Image

View a list of all Linux AMIs in the current AWS Region by using the following command in the AWS CLI

```bash
aws ssm get-parameters-by-path --path /aws/service/ami-amazon-linux-latest --query "Parameters[].Name"
```

#### Instance type

t2.micro is the only instance type available in the free tier.

#### EC2 Creation

```bash
aws ec2 run-instances --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --count 1 --instance-type t2.micro --key-name oeaanup --security-group-ids sg-038586d6829de9c93 --subnet-id subnet-0eb614a78cb9b8051

```
#### output 

```bash
{
    "Groups": [],
    "Instances": [
        {
            "AmiLaunchIndex": 0,
            "ImageId": "ami-041d6256ed0f2061c",
            "InstanceId": "i-086fa543d8bfc82a6",
            "InstanceType": "t2.micro",
            "KeyName": "oeaanup",
            "LaunchTime": "2021-10-11T16:44:25+00:00",
            "Monitoring": {
                "State": "disabled"
            },
            "Placement": {
                "AvailabilityZone": "ap-south-1b",
                "GroupName": "",
                "Tenancy": "default"
            },
            "PrivateDnsName": "ip-172-32-106-192.ap-south-1.compute.internal",
            "PrivateIpAddress": "172.32.106.192",
            "ProductCodes": [],
            "PublicDnsName": "",
            "State": {

```

##### You can list your instances withaws using following command
```bash
aws ec2 describe-instances
```

#### You can set the instance name using following command
```bash
aws ec2 create-tags --resources i-086fa543d8bfc82a6 --tags Key=Name,Value=anup-oea-instance
```

#### Inorder to find the public IP address run the following command
```bash
aws ec2 describe-instances --instance-ids i-086fa543d8bfc82a6 --query "Reservations[0].Instances[0].PublicIpAddress"
```
## EC2 Instance Created With Public IP










  
