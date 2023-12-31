# Terraform Load Balancer

![](https://img.shields.io/badge/Amazon_AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white) ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) ![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white) ![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=for-the-badge&logo=githubactions&logoColor=white)

A simple project to learn AWS automation with Terraform.


## About

This proejct was adapted from [a blog post](https://sharmilas.medium.com/a-step-by-step-guide-to-creating-load-balancer-and-ec2-with-auto-scaling-group-using-terraform-752afd44df8e) by Sharmila S. It was written to get an idea of how infrastructure on AWS can be deployed via Terraform.

By creating this project I have learned the common layout of Terraform code and the need for consistency and specificity in the files. Highlights include misreading "0" as "80" and digging through the [AWS Security Group Rule documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) to troubleshoot, learning the hard way that subnets can only be created in availability zones relevant to the region the VPC is in, and finding that Terraform can pull my AWS config and credentials without me having to specify their location if the AWS CLI is installed on the computer running Terraform. 



## Architecture

![diagram showing AWS components](./READMEimg/diagram1.png)

The Elastic Load Balancer (ELB) is used to spread traffic across multiple servers to decrease the workload on any one server to improve performance and availability. The Auto-Scaling Group (ASG) creates a number of EC2 instances to meet the demand give to it by the ELB. This can increase or decrease to make sure demand is met without over-provisioning resources.

The project sits in its own VPC with a public subnet. This section of the readme is incomplete.