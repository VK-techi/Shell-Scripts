
# Launching Application Load Balancer using AWS CLI


## What is Load Balancing?
Load Balancers are servers that forward internet traffic to multiple servers(EC2) instances downstream.

![App Screenshot](https://github.com/Anup-Narkhede/AWS-Projects/blob/main/Imges/load_balancing.drawio.png)


## Why use a load Balancer?
     + Spread load across multiple downstream instances
     + Expose a single point of access (DNS) to our Application
     + Handle failure of downstream instances
     + Do regular health check of instances
     + High Availaibility across zones



### Types of Load Balancers:

 #### 1.Classic Load Balancer (v1 - old generation) - CLB
       • HTTP, HTTPS, TCP, SSL (secure TCP)
#### 2.Application Load Balancer (v2 - new generation) – ALB
       • HTTP, HTTPS, WebSocket
#### 3.Network Load Balancer (v2 - new generation) – NLB 
       • TCP, TLS (secure TCP), UDP
#### 4.Gateway Load Balancer – GWLB 
       • Operates at layer 3 (Network layer) – IP Protoco

Here we are Creating Application Load Balancer



## Application Load Balancer (v2)
            • Application load balancers is Layer 7 (HTTP)          
            • Load balancing to multiple HTTP applications across machines 
            (target groups)                  
            • Load balancing to multiple applications on the same machine 
            (ex: containers)                                                    
            • Support for HTTP and WebSocket                                        
            • Support redirects (from HTTP to HTTPS for example
  


#### Routing tables to different target groups:

           • Routing based on path in URL (example.com/users & example.com/posts) - We used

![App Screenshot](https://demobucketanup.s3.ap-south-1.amazonaws.com/ALB.png)

           • Routing based on hostname in URL (one.example.com & other.example.com)

           • Routing based on Query String, Headers 
           (example.com/users?id=123&order=false)


           • ALB are a great fit for micro services & container-based application 
           (example: Docker & Amazon ECS




## ---------------------------------------------------------------------------------------------------------------
## SERVICES USED :

1.EC2 Instances  
2.Security Groups  
3.Target Groups  
4.User Data  
5.Application Load Balancer


## Steps:

### 1. Launched 4 Instances in recursively for loop with respective user-data
### 2. Created 4 Target groups in for loop in default VPC and with customized health check config.
### 3. Attached Instance to respective target group  
### 4. Created Application load balancer
### 5. Created Listener for Application Load Balancer to Attach default Target Group

Done
