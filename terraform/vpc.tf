data "aws_availability_zones" "available" {
  state = "available"
}

#------------------------------------------------------------------------------
# vpc / subnets / route tables / igw
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${local.app_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.app_name}-ig"
  }
}




#------------------------------------------------------------------------------
# Public Tier
#------------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.app_name}-rt"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  cidr_block        = "10.0.${count.index+1}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "public-${element(data.aws_availability_zones.available.names, count.index)}"
  }

  map_public_ip_on_launch = true
}

resource "aws_db_subnet_group" "public" {
  name_prefix = local.app_name
  description = "${local.app_name}-public-tier"
  subnet_ids  = aws_subnet.public.*.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  route_table_id = aws_route_table.public.id
  subnet_id      = element(aws_subnet.public.*.id, count.index)
}

#------------------------------------------------------------------------------
# security groups
#------------------------------------------------------------------------------

resource "aws_security_group" "public" {
  name        = "${local.app_name}-public-sg"
  description = "${local.app_name} security group for the public tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}





#------------------------------------------------------------------------------
# Private Tiers
#------------------------------------------------------------------------------

// These cost money so only uncomment when ready to use
//resource "aws_nat_gateway" "main" {
//  allocation_id = aws_eip.nat.id
//  subnet_id     = aws_subnet.public.1.id
//  depends_on = [aws_internet_gateway.main]
//
//  tags = {
//    Name = "NAT-gw"
//  }
//}
//
//resource "aws_eip" "nat" {
//  vpc      = true
//
//  tags = {
//    Project = local.app_name
//  }
//}
//
//resource "aws_route_table" "priv" {
//  vpc_id = aws_vpc.main.id
//
//  route {
//    cidr_block     = "0.0.0.0/0"
//    nat_gateway_id = aws_nat_gateway.main.id
//  }
//
//  tags = {
//    Project = local.app_name
//  }
//}



#------------------------------------------------------------------------------
# Private App Tier
#------------------------------------------------------------------------------
resource "aws_subnet" "priv_app" {
  count             = 2
  cidr_block        = "10.0.${10 + count.index+1}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "priv-app-${element(data.aws_availability_zones.available.names, count.index)}"
  }

  map_public_ip_on_launch = false
}

resource "aws_db_subnet_group" "priv_app" {
  name_prefix = local.app_name
  description = "${local.app_name}-priv-app-tier"
  subnet_ids  = aws_subnet.priv_app.*.id
}

//resource "aws_route_table_association" "priv_app" {
//  count          = 2
//  route_table_id = aws_route_table.priv.id
//  subnet_id      = element(aws_subnet.priv_app.*.id, count.index)
//}

#------------------------------------------------------------------------------
# security groups
#------------------------------------------------------------------------------

resource "aws_security_group" "priv_app" {
  name        = "${local.app_name}-priv-app-sg"
  description = "${local.app_name} security group for the private application tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    security_groups = [aws_security_group.public.id]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    security_groups = [aws_security_group.bastion.id]
  }


  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}




#------------------------------------------------------------------------------
# Private Data Tier
#------------------------------------------------------------------------------
resource "aws_subnet" "priv_data" {
  count             = 2
  cidr_block        = "10.0.${20 + count.index+1}.0/24"
  vpc_id            = aws_vpc.main.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "priv-data-${element(data.aws_availability_zones.available.names, count.index)}"
  }

  map_public_ip_on_launch = false
}

resource "aws_db_subnet_group" "priv_data" {
  name_prefix = local.app_name
  description = "${local.app_name}-priv-data-tier"
  subnet_ids  = aws_subnet.priv_app.*.id
}

//resource "aws_route_table_association" "priv_data" {
//  count          = 2
//  route_table_id = aws_route_table.priv.id
//  subnet_id      = element(aws_subnet.priv_data.*.id, count.index)
//}

#------------------------------------------------------------------------------
# security groups
#------------------------------------------------------------------------------

resource "aws_security_group" "priv_data" {
  name        = "${local.app_name}-priv-data-sg"
  description = "${local.app_name} security group for the private data tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5439
    to_port     = 5439
    security_groups = [aws_security_group.priv_app.id]
  }

    ingress {
      description = "bastion"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      security_groups = [aws_security_group.bastion.id]
    }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


