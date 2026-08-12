data "aws_availability_zones" "available" {
  state = "available"
}

# Existing VPC that survived the Task 2 destroy — read only, not managed here
data "aws_vpc" "main" {
  id = var.existing_vpc_id
}

# Existing DB subnets (RDS still uses them) — read only, not managed here
data "aws_subnet" "private_db" {
  count = length(var.existing_private_db_subnet_ids)
  id    = var.existing_private_db_subnet_ids[count.index]
}

# ── Internet Gateway (was destroyed, recreating) ─────────────
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ── Public Subnets — ALB + NAT Gateway (recreating) ──────────
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
  }
}

# ── Private App Subnets — ECS Fargate tasks (recreating) ─────
resource "aws_subnet" "private_app" {
  count             = length(var.private_app_subnet_cidrs)
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.project_name}-${var.environment}-private-app-${count.index + 1}"
  }
}

# ── NAT Gateway (recreating) ──────────────────────────────────
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-${var.environment}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id
  tags          = { Name = "${var.project_name}-${var.environment}-nat" }
  depends_on    = [aws_internet_gateway.main]
}

# ── Route Tables (recreating) ─────────────────────────────────
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-private-rt" }
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Re-attach surviving DB subnets to the new private route table
# (their old association was destroyed along with everything else)
resource "aws_route_table_association" "private_db" {
  count          = length(data.aws_subnet.private_db)
  subnet_id      = data.aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}