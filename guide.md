# How It's Made

### About

This guide assumes you have already [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.htm) the AWS CLI and have [Terraform installed on your computer](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). Throughout the guide are code snippets from the files in this project. To keep you on your toes they require you to input your resource names etc. No brainless copy/paste allowed.

---
### 0. Prerequisite Knowledge

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

---

### 1. Project Setup

After creating the project's root directory create the `main.tf` file and add the provider for AWS:

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

If you haven't already set up a `.gitignore` file, do so now and add the Terraform state files to it or copy GitHub's [Terraform.gitignore template](https://github.com/github/gitignore/blob/main/Terraform.gitignore). It is bad practice to [store the state files somewhere public](https://developer.hashicorp.com/terraform/language/state/sensitive-data). If you're a madlad who likes his or her S3 buckets then add the following code to `main.tf` to store the state in an existing, private S3 bucket:

```hcl
terraform {
    backend "s3" {
      bucket = "<your-bucket-here>"
      region = "<your-region-here>"
      key    = "path/to/directory"
    }
}
```

With your state file safely locked away from prying eyes, go ahead and run `terraform init` to initalise the project by downloading the specified providers.

---

### 2. Configuring The VPC & Subnets

The project requires a VPC with two public subnets and one private subnet. This is covered in the "Architecture" section of the repo's [readme](./README.md).

As this project involves several moving parts it's best to keep things organised. This is best done by having separate `.tf` files for each aspect. Create the `vpc-with-subnets.tf` file and add the block for the first subnet.

```hcl
resource "aws_vpc" "<vpc-name-here>" {
  cidr_block = "10.0.0.0/23"
  tags = {
    Name = "<vpc-name-here>"
  }
}
```
I've given it a nice big /23 subnet, but for production environments you'll have to consider how many addresses you'll actually need.

Next, add in the subnet code block for the first public subnet:

```hcl
resource "aws_subnet" "<subnet1-name-here>" {
  vpc_id                  = aws_vpc.<vpc-name-here>.id
  cidr_block              = "10.0.0.0/27"
  map_public_ip_on_launch = true
  availability_zone       = "<your-region-here>"
}
```

Note that the subnet size is smaller (this is a subnet of the VPC subnet) and that `map_public_ip_on_launch` is set to `true` as this subnet is to be public. Add the second subnet code block changing the details where appropriate. See if you can figure it out on your own using your networking knowledge.

<details>
<summary>(only click here if you're really stuck)</summary>

The second subnet starts after the end of the first subnet. The mask is a /27 which gives us 32 addresses. Starting at address 0, the next subnet begins at 10.0.0.32. The subnet name is different to the first subnet and `map_public_ip_on_launch` is set to `true`.
```hcl
resource "aws_subnet" "<subnet2-name-here>" {
  vpc_id                  = aws_vpc.<vpc-name-here>.id
  cidr_block              = "10.0.0.32/27"
  map_public_ip_on_launch = true
  availability_zone       = "<your-region-here>"
}
```

Hopefull you're just here checking your work, if not then never mind champ you'll get it next time. I believe in you.
</details>

Finally, add the private subnet code block. Note `map_public_ip_on_launch` is set to `false` this time. Why might that be?

```hcl
resource "aws_subnet" "<subnet3-name-here>" {
  vpc_id                  = aws_vpc.<vpc-name-here>.id
  cidr_block              = "10.0.1.0/27"
  map_public_ip_on_launch = false
  availability_zone       = "<your-region-here>"
}
```
---

### 3. NAT Gateway & Route Tables

I've split this part into two files, `gateways-private.tf` and `gateways-public.tf`. Let's start with setting up the public gateway. This will allow the load balancer to communicate on the public internet so users can access the services and resources behind it.

First define the Internet Gateway and place it in the VPC we created in the previous step:

```hcl
resource "aws_internet_gateway" "albtf_gw" {
  vpc_id = aws_vpc.<vpc-name-here>.id
}
```

Now add in the code block for creating the route table. This requires   