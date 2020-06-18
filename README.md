# <client> Reference Architecture Infrastructure Overview

This reference architecture deployed on top of [Amazon Web Services (AWS)](https://aws.amazon.com) is production-ready, best practices and end-to-end tech stack built using Infrastructure as Code. 

![Infrastructure](images/reference-architecture.png)

The Reference Architecture is highly customisable, so what's deployed may be a bit different from what is in the diagram.  Here is an overview of what is actually deployed:

1. [Infrastructure as code](#infrastructure-as-code)
1. [Environments](#environments)
1. [AWS accounts](#aws-accounts)
1. [VPCs and subnets](#vpcs-and-subnets)
1. [Load balancers](#load-balancers)
1. [Docker clusters (ECS)](#docker-clusters)
1. [Data stores](#data-stores)
1. [OpenVPN server](#openvpn-server)
1. [CircleCI](#circleci)
1. [Monitoring, log aggregation, alerting](#monitoring-log-aggregation-alerting)
1. [DNS and TLS](#dns-and-tls)
1. [Static content, S3, and CloudFront](#static-content-s3-and-cloudfront)
1. [Lambda](#lambda)
1. [Security](#security)




## Infrastructure as code

The infrastructure is managed as **code**, primarily using [Terraform](https://www.terraform.io/). 
That is, instead of clicking around a web UI or SSHing to a server and manually executing commands, the idea behind 
infrastructure as code (IaC) is that you write code to define your infrastructure and you let an automated tool (e.g.,
Terraform) apply the code changes to your infrastructure. This has a number of benefits:

* You can automate your entire provisioning and deployment process, which makes it much faster and more reliable than 
  any manual process.

* You can represent the state of your infrastructure in source files that anyone can read rather than a sysadmin's head.

* You can store those source files in version control, which means the entire history of your infrastructure is 
  captured in the commit log, which you can use to debug problems, and if necessary, roll back to older versions.

* You can validate each infrastructure change through code reviews and automated tests.

* You can package your infrastructure as reusable, documented, battle-tested modules that make it easier to scale and 
  evolve your infrastructure. 

# Environments

The infrastructure is deployed across multiple environments:

* **dev** (account id): Sandbox environment. 

* **prod** (account id): Production environment. 

* **security** (account id): All IAM users and permissions are defined in this account. 

* **shared-services** (account id): DevOps tooling, such as the OpenVPN server. 

* **stage** (account id): Pre-production environment. 





## AWS accounts

The infrastructure is deployed across multiple AWS accounts. For example, the development environment is in one account,
the production environment in another account, the DevOps tooling in yet another account, and so on. This gives you 
better isolation between environments so that if you break something in one environment (e.g., staging)—or worse yet, a 
hacker breaks into that environment—it should have no effect on your other environments (e.g., prod). It also gives you
better control over what resources each employee can access. This concept is known as defense in depth. 


## VPCs and subnets

Each environment lives in a separate [Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/), which is a logically 
isolated section within an AWS account. Each VPC defines a virtual network, with its own IP address space and rules for 
what can go in and out of that network. The IP addresses within each VPC are further divided into multiple 
[subnets](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html), where each subnet controls the 
routing for its IP address. 

* *Public subnets* are directly accessible from the public Internet.
* *Private subnets* are only accessible from within the VPC. 

Just about everything in this infrastructure is deployed in private subnets to reduce the surface area to attackers. 
The only exceptions are load balancers and the OpenVPN server, both of which are described below. 

## Load balancers

Traffic from the public Internet (e.g., requests from your users) initially goes to a *public load balancer*, which 
proxies the traffic to your apps. This allows you to run multiple copies of your application for scalability and high 
availability. The load balancers being used are:

* [Application Load Balancer (ALB)](https://aws.amazon.com/elasticloadbalancing/applicationloadbalancer/): The ALB is a
  load balancer managed by AWS that is designed for routing HTTP and HTTPS traffic. The advantage of using a managed
  service is that AWS takes care of fault tolerance, security, and scaling the load balancer for you automatically.
 

We also deploy an *internal* load balancer in the private subnets. This load balancer is not accessible to the public.
Instead, it's used as a simple way to do service discovery: every backend service registers with the load balancer at a
particular path, and all services know to send requests to this load balancer to talk to other services.




## Docker clusters

The application code is packaged into [Docker containers](http://docker.com/) and deployed across an Amazon
[EC2 Container Service (ECS)](https://aws.amazon.com/ecs/) cluster.
The advantage of Docker is that it allows you to package
your code so that it runs exactly the same way in all environments (dev, stage, prod). The advantage of a Docker 
Cluster is that it makes it easy to deploy your Docker containers across a cluster of servers, making efficient use of
wherever resources are available. Moreover, ECS can automatically scale your app up and down in response to load and 
redeploy containers that crashed.

For a quick intro to Docker, see [Running microservices on AWS using Docker, Terraform, and 
ECS](http://www.ybrikman.com/writing/2016/03/31/infrastructure-as-code-microservices-aws-docker-terraform-ecs/).


## Data stores

The infrastructure includes the following data stores:

1. **Postgres**: Postgres is deployed using [Amazon's Relational Database Service 
  (RDS)](https://aws.amazon.com/rds/), including automatic failover, backups, and replicas. 
  
  
  1. **Memcached**: Memcached is deployed using [Amazon's ElastiCache 
  Service](https://aws.amazon.com/elasticache/), including automatic failover, backups, and replicas. 



## Lambda

We have deployed several example [Lambda functions](https://aws.amazon.com/lambda/) to show how you can build 
serverless applications. 

## OpenVPN server

To reduce your surface area to attackers, just about all of the resources in this infrastructure run in private subnets, 
which are not accessible from the public Internet at all. To allow developers access to these 
private resources, we expose a single server publicly: an [OpenVPN server](https://openvpn.net/). Once you connect to 
the server using a VPN client, you are "in the network", and will be able to access the private resources (e.g., you 
will be able to SSH to your EC2 Instances).


## CircleCI

We have set up [CircleCi](https://circleci.com/) as a Continuous Integration (CI) server. After every commit, a CircleCi 
job runs your build, tests, packaging, and automated deployment steps.
 
## Monitoring, log aggregation, alerting

You can find metrics, log files from all your servers, and subscribe to alert notifications using [Amazon 
CloudWatch](https://aws.amazon.com/cloudwatch/).  


## DNS and TLS

[Amazon Route 53](https://aws.amazon.com/route53/) is used to configure DNS entries for all your services. We
have configured SSL/TLS certificates for domain names using [Amazon's Certificate Manager 
(ACM)](https://aws.amazon.com/certificate-manager/), which issues certificates that are free and renew automatically.


## Static content, S3, and CloudFront

All static content (e.g., images, CSS, JS) is stored in [Amazon S3](https://aws.amazon.com/s3/) and served via the 
[CloudFront](https://aws.amazon.com/cloudfront/) CDN. This allows you to offload all the work of serving static content 
from your app server and reduces latency for your users.

## Security

Security best practices is built in every aspect of this infrastructure:
 
* **Network security**

* **Server access**

* **Application secrets**
 
* **User accounts**
 
* **Auditing**

* **Intrusion detection**

* **Security updates**

* **OS hardening**

* **End-to-end encryption**

