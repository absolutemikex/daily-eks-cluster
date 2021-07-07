resource "aws_security_group" "stsendpointsg" {
  name = "stssg"
  description = "Security Group for STS VPC Endpoint"
  vpc_id = module.vpc.vpc_id

  ingress {
    cidr_blocks = [ "10.0.0.0/16", "100.64.0.0/16" ]
    description = "From VPC"
    from_port = 0
    protocol = "tcp"
    to_port = 0
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Outbound"
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

resource "aws_security_group" "clustersg" {
  name = "clustersg"
  description = "Security Group for STS VPC Endpoint"
  vpc_id = module.vpc.vpc_id

  ingress {
    cidr_blocks = [ "10.0.0.0/16", "100.64.0.0/16" ]
    description = "From VPC"
    from_port = 0
    protocol = "tcp"
    to_port = 0
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Outbound"
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

resource "aws_security_group" "podsg" {
  name = "podsg"
  description = "Security Group for Pods"
  vpc_id = module.vpc.vpc_id
  
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Inbound"
    from_port = 0
    protocol = "-1"
    to_port = 0
  }

    egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Outbound"
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "simple-eks-vpc"
  cidr = "10.0.0.0/16"
  secondary_cidr_blocks = ["100.64.0.0/16"]

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "100.64.0.0/19","100.64.32.0/19","100.64.64.0/19"]
  public_subnets  = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames = true
  enable_dns_support = true
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/adtech-devops" = "shared"
  }
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/adtech-devops" = "shared"
  }

  tags = {
    Terraform = "true"
    Environment = "Dev"
  }
}

resource "aws_vpc_endpoint" "sts" {
  service_name = "com.amazonaws.us-east-1.sts"
  vpc_id = module.vpc.vpc_id
  subnet_ids = [ "subnet-06d026a92f5dbf212",
                  "subnet-042623630bca5c2c6",
                  "subnet-0ba25971808ebef07" ]
  security_group_ids = [ aws_security_group.stsendpointsg.id ]
  vpc_endpoint_type = "Interface"
}

######Outputs

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "eks_cluster_sg" {
  value = aws_security_group.clustersg.id
}