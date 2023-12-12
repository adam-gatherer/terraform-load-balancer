# AWS Terraform Load Balancer

### About

This guide assumes you have already [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.htm) the AWS CLI and have [Terraform installed on your computer](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli). Throughout the guide are code snippets from the files in this project. To keep you on your toes they require you to input your resource names etc. No brainless copy/paste allowed.

---
### 0 - Prerequisite Knowledge

- Networking
    - [Public/private networking](https://simple.wikipedia.org/wiki/IP_address)
    - [Subnets](https://www.dummies.com/article/technology/information-technology/networking/general-networking/network-administration-subnet-basics-184551/)
    - [Routing](https://www.dummies.com/article/technology/information-technology/networking/general-networking/network-basics-routers-185331/)
    - [NAT](https://www.computernetworkingnotes.com/ccna-study-guide/basic-concepts-of-nat-explained-in-easy-language.html)
    - [Network Ports](https://simple.wikipedia.org/wiki/Network_port)
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

### 1 - Project Setup

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

The provider will need configured to use the region in which the project will be deployed. If you have set up the AWS CLI with your access keys then Terraform should pick these up. Otherwise these can be specified here:


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

### 2 - Configuring The VPC & Subnets

The project requires a VPC with two public subnets and one private subnet. This is covered in the "Architecture" section of the repo's [readme](../README.md).

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

### 3 - NAT Gateway & Route Tables

I've split this part into two files, `gateways-private.tf` and `gateways-public.tf`. Let's start with setting up the public gateway. This will allow the load balancer to communicate on the public internet so users can access the services and resources behind it.

#### 3.1 - Public Gateway

First define the Internet Gateway and place it in the VPC we created in the previous step:

```hcl
resource "aws_internet_gateway" "<gw1-name-here>" {
  vpc_id = aws_vpc.<vpc-name-here>.id
}
```

Now add in the code block for creating the route table. This requires the VPC ID, the route(s) it will hold, and the ID of the gateway it will sit on.

```hcl
resource "aws_route_table" "<rt1-name-here>" {
  vpc_id = aws_vpc.<vpc-name-here>.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.<gw1-name-here>.id
  }
}
```

The gateway and route table are looking very nice but won't do anything until the table is attached to a subnet. The following code block associates the route table to our first public subnet:

```hcl
resource "aws_route_table_association" "<rta1-name-here>" {
  subnet_id      = aws_subnet.<subnet1-name-here>.id
  route_table_id = aws_route_table.<rt1-name-here>.id
}
```

As before, see if you can figure out how to repeat this for our second public subnet.

<details>
<summary>(only click here if you're really stuck)</summary>

```hcl
resource "aws_route_table_association" "<rta2-name-here>" {
  subnet_id      = aws_subnet.<subnet2-name-here>.id
  route_table_id = aws_route_table.<rt1-name-here>.id
}
```
</details>

#### 3.2 - Private Gateway

Similar to the public gateway but set up to only allow requests from the load balancer to reach the EC2 instances whilst allowing all traffic from them to pass out. This is done with a NAT gateway. The gateway sits between the public subnet with internet access (created in the previous step) and the private subnet.

To access the internet, the gateway will need an elastic IP:

```hcl
resource "aws_eip" "<eip-name-here>" {
  depends_on = [aws_internet_gateway.<gw1-name-here>]
  vpc        = true
  tags = {
    Name = "<eip-name-here>"
  }
}
```

Note the use of `depends_on` - this means the EIP won't be created until after the referenced gateway is created. Can't assign an IP address to nothing. We'll be seeing it again.

The NAT gateway also `depends_on` the internet gateway existing:

```hcl
resource "aws_nat_gateway" "<natgw-name-here>" {
  allocation_id = aws_eip.<eip-name-here>.id
  subnet_id     = aws_subnet.<subnet1-name-here>.id
  tags = {
    Name = "<natgw-name-here>"
  }
  depends_on = [aws_internet_gateway.<gw1-name-here>]
}
```

We'll need a route table for the private subnet to connect out to the internet. This is done by providing a route to 0.0.0.0/0, which will match all destination IP addresses and act as a default route. 

```hcl
resource "aws_route_table" "<rt2-name-here>" {
  vpc_id = aws_vpc.<vpc-name-here>.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.<natgw-name-here>.id
  }
}
```

And finally, the route table will need associated with the private subnet. You know what to do here.

<details>
<summary>(only click here if you're really stuck)</summary>

```hcl
resource "aws_route_table_association" "<rta3-name-here>" {
  subnet_id      = aws_subnet.<subnet3-name-here>.id
  route_table_id = aws_route_table.<rt2-name-here>.id
}
```
As before, we create the route table association resource then specify that our NAT gateway route table is going into our private subnet.

</details>

---

### 4 - Load Balancer

The load balancer will balance traffic between all targets in the target group. Because we're balancing traffic for specific port numbers we'll use an application laod balancer. Start by setting up the LB itself:

```hcl
resource "aws_lb" "<lb-name-here>" {
  name               = "<lb-name-here>"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.<lbsg-name-here>.id]
  subnets            = [aws_subnet.<subnet1-name-here>.id, aws_subnet.<subnet2-name-here>.id]
  depends_on         = [aws_internet_gateway.<gw1-name-here>]
}
```

The security group that governs the LB has not been created yet (we'll handle security later). Note the subnets the LB is a member of and what it `depends_on` being created first.

The target group is set up to operate on port 80. I've left the protocol name out, let's see if you can figure out what four letter protocol runs on port 80.

```hcl
resource "aws_lb_target_group" "<tg-name-here>" {
  name     = "<tg-name-here>"
  port     = 80
  protocol = "<omitted-to-make-you-think>"
  vpc_id   = aws_vpc.<vpc-name-here>.id
}
```

And to listen for traffic coming in, the LB needs a listener. It'd be easy if I gave you the protocol here after asking for it earlier but we don't do things because they are easy. The listener needs some actions to do, in this case we want it to forward traffic from port 80 to the target group we defined earlier.

```hcl
resource "aws_lb_listener" "<lbl-name-here>" {
  load_balancer_arn = aws_lb.<lb-name-here>.arn
  port              = "80"
  protocol          = "<omitted-to-make-you-think>"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.<tg-name-here>.arn
  }
}
```
<details>
<summary>(only click here if you're really stuck)</summary>

Port 80 is used by the HTTP protocol. You should know this already if you're going to start learning cloud engineering.

</details>

---

### 5 - Auto Scaling

