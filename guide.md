# How It's Made

### Prerequisite Knowledge

- Networking
    - [Public/private networking](https://simple.wikipedia.org/wiki/IP_address)
    - [Subnets](https://www.dummies.com/article/technology/information-technology/networking/general-networking/network-administration-subnet-basics-184551/)
    - [Routing](https://www.dummies.com/article/technology/information-technology/networking/general-networking/network-basics-routers-185331/)
- AWS
    - [EC2 basics](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)
    - [Elastic Load Balancers](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html)
    - [Auto Scaling Groups](https://docs.aws.amazon.com/autoscaling/ec2/userguide/auto-scaling-groups.html)
    - AWS Networking ([Elastic IP](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/elastic-ip-addresses-eip.html), [NAT Gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html), [Route tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html))
- Terraform
    - [Working with AWS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- GitHub
    - [Basic operation](https://docs.github.com/en/get-started/quickstart/hello-world)
    - [.gitignore file](https://docs.github.com/en/get-started/getting-started-with-git/ignoring-files)
    - [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)

### 1. Setup

This guide assumes you have already [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.htm) the AWS CLI and have [Terraform installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) on your computer.

After creating the project's root directory create the main.tf file and add the provider for AWS:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
  }
}
```

The provider will need configured to use the region you're going to deploy the project in. If you have set up the AWS CLI with your access keys then Terraform should pick these up. Otherwise these can be specified here:

```hcl
provider "aws" {
  region                   = "<your-region-here>"
  shared_config_files      = ["/Path/to/.aws/config"]
  shared_credentials_files = ["/Path/to/.aws/credentials"]
  profile                  = "PROFILE"
}
```

If you haven't already set up a `.gitignore` file, do so now and add the Terraform state files to it or copy GitHub's [Terraform.gitignore template](https://github.com/github/gitignore/blob/main/Terraform.gitignore). It is bad practice to [store the state files somewhere public](https://developer.hashicorp.com/terraform/language/state/sensitive-data). 
