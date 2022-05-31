# Fetching all availability zones in us-east-1

###################################################

data aws_availability_zones this {}

#######################################################
### VPC and subnets
#######################################################

resource aws_vpc this {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    var.tags,
    { "Name" = var.vpc_name }
  )

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource aws_vpc_ipv4_cidr_block_association this {
  count = length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

resource aws_subnet public {
  count = length(var.public_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index].cidr
  availability_zone = data.aws_availability_zones.this.names[count.index]

  tags = { "Name" = var.public_subnets[count.index].name }
}

resource aws_subnet private {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index].cidr
  availability_zone = data.aws_availability_zones.this.names[count.index]

  tags = { "Name" = var.private_subnets[count.index].name }
}

#######################################################
### Internet GW and NAT GW
#######################################################

resource aws_internet_gateway this {
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    { "Name" = "${var.vpc_name}-IGW" }
  )
}

resource aws_eip nat {
  count = var.enable_nat_gateway ? length(var.public_subnets) : 0

  vpc = true

  tags = merge(
    {
      "Name" = "${var.public_subnets[count.index].name}-nat-eip"
    },
    var.tags
  )
}

resource aws_nat_gateway this {
  count = var.enable_nat_gateway ? length(var.public_subnets) : 0

  allocation_id = element(aws_eip.nat.*.id, count.index)

  subnet_id = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    {
      "Name" = "${var.public_subnets[count.index].name}-natgw"
    },
    var.tags
  )
}

#######################################################
### Route tables
#######################################################

resource aws_route_table public {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      "Name" = "${var.vpc_name}-RT-inet"
    },
    var.tags
  )
}

resource aws_route_table private {
  count = var.enable_nat_gateway ? length(var.private_subnets) : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(
    {
      "Name" = "${var.vpc_name}-RT-private"
    },
    var.tags
  )
}

resource aws_route_table_association public {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource aws_route_table_association private {
  count = length(var.private_subnets)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

#######################################################
### Security groups
#######################################################
resource aws_security_group private {
  name        = "SG for Private subnets"
  description = "Allow HTTP/HTTPS and management inbound traffic"
  vpc_id      = aws_vpc.this.id

  ##################### Egress rules

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  ##################### Ingress rules
  ingress {
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    from_port   = 0
    to_port     = 0
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = [var.source_ssh_ip_enabled]
    from_port   = 22
    to_port     = 22
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  tags = merge(
    {
      "Name" = "${var.vpc_name}-SG-private"
    },
    var.tags
  )
}

resource aws_security_group public {
  name        = "SG for Public subnets to allow web connections"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.this.id

  ##################### Egress rules
  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  ##################### Ingress rules

  ingress {
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    from_port   = 0
    to_port     = 0
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  # ingress {
  #   protocol   = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  #   from_port  = 443
  #   to_port    = 443
  # }

  tags = merge(
    {
      "Name" = "${var.vpc_name}-SG-public"
    },
    var.tags
  )
}