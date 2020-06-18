# <client> Reference Architecture Infrastructure Overview

This reference architecture deployed on top of [Amazon Web Services (AWS)](https://aws.amazon.com) is production-ready, best practices and end-to-end tech stack built using Infrastructure as Code. 

## Repo Layout
* Environments - Environments state files with its own variables.
* Images - Architecture diagrams
* Modules - Infrastructure orchestration and templates

![Infrastructure](images/reference-architecture.png)

## Getting started
To use this repo first, you should get familiar with [Terraform](https://terraform.io).
This repo is used to deploy the dev, stage and prod environments and to bring up all private and public services.

## Terraform Structure
The Terraform code is divided into several directories:
* `modules`: These are low level components, they are reused all over the codebase, but shouldn't be called directly from an `environment`.
* `environments`: They are an instance of a stack, and allow us to duplicate stacks easily. Terraform should only be executed from the environment directories, as it will produce `tfstate` files describing these environments in AWS.
## Modules Introduction
* `alb`: It is used to create an internal alb and an external alb in the `stacks` modules.
* `elasticache`: It is the one who creates the Redis cluster.
* `cloudfront`: Creates a cloudfront service for CDN.
* `ecs-autoscaling`: Creates an ECS cluster with autoscaling and cloudwatch alarms attached.
* `ecs-delayjob`: Creates three ECS Services inside ECS cluster without auto scaling nor cloudwatch alarms.
* `ecs-service`: Creates a ECS Service inside ECS cluster with autoscaling and cloudwatch alarms.
* `elasticache`: Creates a elasticache service for Redis.
* `network`: Has the VPC and subnets creation.
* `rds`: It is used to create the postgres databases.
* `ssm`: Creates and encrypts the generated secrets (RDS and Redis endpoints).
## Creating a new environment
Inside the `infrastructure` directory, you'll find all the code to manage a stack.
Most of the time you'll just need to work from the `environments` directory.
You should only use the `terraform` command from one of the `environments` directory. The `modules` directory should only be included into environment stacks.
When creating a new environment, we should always append an id to the end. The only times this isn't the case are for the `core` and `global` environments, which are unique environments in the entire infrastructure. But it's very likely that other environments will be duplicated several times.
## Terraform variables

### Setting up the enviroment:
| Name | Description | Type |
| ------------- |:-------------:| -----:|
| provider | Specify the region to deploy. | Map |
| enviroment | Specify the enviroment type. | String |
| vpc | Define the vpc settings. | Map |
| private_subnets | Define all three private settings. | Map |
| public_subnets | Define all three public settings. | Map |
| az_count | Specify the number of availability zones. | String |
| alb_certificate_arn | ARN of the alb certificate. | String |
| desired_capacity | Desired capacity of the EC2 instances register to the cluster of ECS. | String |
| ecs_max_size | Maximum number of EC2 instances register to the cluster of ECS. | String |
| ecs_min_size | Minimum number of EC2 instances register to the cluster of ECS. | String |
| key_name | KeyPair name for EC2 instances register to the cluster. | String |
| instance_type | Instance family type for EC2 instance register to the cluster. | String |
| database | Database settings for RDS instance. | Map |
| service_name | Service name defined for ECS Service. | String |
| backfill_service_name | Service name defined for ECS Service. | String |
| serial_service_name | Service name defined for ECS Service. | String |
| rails_ecr | ECR Repository of Docker images for Rails. | String |
| rails_tag | Tag that identify the docker image. | String |
| rails_cpu | CPU allocation for task definition. | String |
| rails_mem | RAM MEM allocation for task definition. | String |
| nginx_ecr | ECR Repository of Docker images for nGinx. | String |
| nginx_tag | Tag that identify the docker image. | String |
| nginx_cpu | CPU allocation for task definition. | String |
| nginx_mem | RAM MEM allocation for task definition. | String |
| containerPort | Container port exposed from the container. | String |
| task_count | Number of task running in the service | String |
| cpu_up_eval_periods | Number of periods of evaluation to trigger the CloudWatch alarm as Alarm. | String |
| cpu_up_period | Number of seconds between evaluation of the metric of CloudWatch. | String |
| cpu_up_threshold | Threshold number to change state of alarm. | String |
| mem_up_eval_periods | Number of periods of evaluation to trigger the CloudWatch alarm as Alarm. | String |
| mem_up_period | Number of seconds between evaluation of the metric of CloudWatch. | String |
| mem_up_threshold | Threshold number to change state of alarm. | String |
| cpu_down_eval_periods | Number of periods of evaluation to trigger the CloudWatch alarm as Alarm. | String |
| cpu_down_period | Number of seconds between evaluation of the metric of CloudWatch. | String |
| cpu_down_threshold | Threshold number to change state of alarm. | String |
| mem_down_eval_periods | Number of periods of evaluation to trigger the CloudWatch alarm as Alarm. | String |
| mem_down_period | Number of seconds between evaluation of the metric of CloudWatch. | String |
| mem_down_threshold | Threshold number to change state of alarm. | String |
| delayed_cpu | CPU allocation for task definition. | String |
| delayed_mem | RAM MEM allocation for task definition. | String |
| elasticache_engine_version | Redis version to start a cluster of Elasticache. | String |
| parameter_group_name | Parameters of the redis cluster. | String |
| elasticache_instance_type | Instance type of elasticache cluster. | String |
| maintenance_window | Maintenance windows to upgrade elasticache cluster. | String |


## General Rules
1. Commit similar resources together, for example. Compute, Autoscaling, Cloudwatch should be separate from storage, network or other services. In Compute, we can have further division into Beanstalk, ECS, EKS, etc. depending on launch type.

2. Update existing folder only in case of functional upgrade. Create PR and need to be reviewed by at least another member of Augeos

3. Do not use resource id or client specific parameters in the resource declaration file.

4. Use conditionals for recurring use cases of resource linkage. For example, IAM Policy attachment, target group attachment, autoscaling attachment etc.

5. Create README.md for each folder you create. This will help with documentation.

### CloudFormation Rules
1. All parameters must have default values.

2. Use NoEcho property to obfuscate sensitive values in parameters

3. Use CloudFormation *Metadata* for master templates to be user friendly.

4. Use *yml* syntax as much as possible. Try to not create IAM policies or any other type using json syntax.

### Terraform Rules
1. Use join, split and square brackets to use list variables, avoid using variables for each member of the list. To reference a specific member of a list, use the index no. starting from 0
2. Local names of resource types can't contain any reference to client or environment specific. The environment is to be specified in name attribute and in tags if needed.
3. Use as few defaults as possible within the module variables. Defer parameter application to the main folder.
4. Use templates to generate strings for other Terraform resources or outputs. Avoid using inline commands for user script, use .tpl files to store these commands and render it through template data sources.
5. Use variables only, for environment capacities such as exposed ports, memory, cpu, task-definition id etc.

![Terraform Rules](images/terraformmodules.png)

## Best practices
+ Always use the core infrastructure to have all the features so we can start improving our generalised repository.

+ If you want to make a change in the core infrastructure, raise a PR and let at least a member of the team review it. In this way we ensure we use the best possible solution in all clients.

+ Don't commit any resource id, company name nor account id. Make sure of it. Instead use the word *company*.
