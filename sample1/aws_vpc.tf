# VPC
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc.html
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "microservices"
  }
}

# Subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet.html
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "microservices-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "microservices-public-1c"
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "microservices-private-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "microservices-private-1c"
  }
}

# Internet Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway.html
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microservices"
  }
}

# Elastic IP
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip.html
resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "microservices-natgw-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "microservices-natgw-1c"
  }
}

# NAT Gateway
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway.html
resource "aws_nat_gateway" "nat_1a" {
  subnet_id     = aws_subnet.public_1a.id
  allocation_id = aws_eip.nat_1a.id

  tags = {
    Name = "microservices-1a"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  subnet_id     = aws_subnet.public_1c.id
  allocation_id = aws_eip.nat_1c.id

  tags = {
    Name = "microservices-1c"
  }
}

# Route Table
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table.html
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microservices-public"
  }
}

# Route
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route.html
resource "aws_route" "public" {
  route_table_id          = aws_route_table.public.id
  gateway_id              = aws_internet_gateway.main.id
  destination_cidr_block  = "0.0.0.0/0"
}

# Association
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association.html
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# Route Table (Private)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table.html
resource "aws_route_table" "private_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microservices-private-1a"
  }
}

resource "aws_route_table" "private_1c" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "microservices-private-1c"
  }
}

# Route (Private)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route.html
resource "aws_route" "private_1a" {
  route_table_id          = aws_route_table.private_1a.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1c" {
  route_table_id          = aws_route_table.private_1c.id
  nat_gateway_id         = aws_nat_gateway.nat_1a.id
  destination_cidr_block = "0.0.0.0/0"
}

# Association (Private)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association.html
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_1a.id
}

resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_1c.id
  route_table_id = aws_route_table.private_1c.id
}



# #----------------------------------------
# # セキュリティグループの作成
# #----------------------------------------
# resource "aws_security_group" "sample_sg" {
#   name   = "sample-sg"
#   vpc_id = aws_vpc.sample_vpc.id
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
