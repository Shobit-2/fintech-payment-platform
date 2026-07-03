resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # required for EKS - nodes/pods need DNS resolution

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Public Subnets ---
# One per AZ. Hosts: Jenkins EC2, NAT Gateway(s), load balancer nodes.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block               = var.public_subnet_cidrs[count.index]
  availability_zone        = var.availability_zones[count.index]
  map_public_ip_on_launch  = true # instances here get a public IP automatically

  tags = {
    Name                                          = "${var.project_name}-public-${var.availability_zones[count.index]}"
    # This tag is required by the AWS Load Balancer Controller / EKS to
    # auto-discover which subnets are suitable for internet-facing load
    # balancers. We add it now so Stage 8 (K8s Ingress) works without
    # manual reconfiguration later.
    "kubernetes.io/role/elb"                      = "1"
  }
}

# --- Private Subnets ---
# One per AZ. Hosts: EKS worker nodes, RDS. No direct internet route.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                     = "${var.project_name}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb"        = "1"
  }
}

# --- Elastic IP(s) for NAT Gateway ---
resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

# --- NAT Gateway(s) ---
# Must live in a PUBLIC subnet (it needs its own route to the IGW), even
# though its purpose is to serve PRIVATE subnets' outbound traffic.
resource "aws_nat_gateway" "main" {
  count = var.single_nat_gateway ? 1 : length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.main]
}

# --- Public Route Table ---
# Single shared route table for all public subnets: 0.0.0.0/0 -> Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- Private Route Table(s) ---
# 0.0.0.0/0 -> NAT Gateway. If single_nat_gateway=true, every private subnet
# shares one route table pointing at the one NAT Gateway. If false, each AZ
# gets its own route table pointing at its own AZ's NAT Gateway (keeps
# traffic within the AZ, avoiding cross-AZ data transfer cost, and removes
# the single point of failure).
resource "aws_route_table" "private" {
  count  = var.single_nat_gateway ? 1 : length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = var.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}
