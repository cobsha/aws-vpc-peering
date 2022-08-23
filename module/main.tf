resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.project
    project = var.project
    env = var.env
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project}-${var.env}-igw"
    project = var.project
    env = var.env
  }
}

resource "aws_subnet" "public" {
  
  count = 2
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone = "${var.region}${var.zone[count.index]}"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project}-public-${count.index + 1}"
    project = var.project
    env = var.env
  }
}

resource "aws_subnet" "private" {
  
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 2, 2)
  availability_zone = "${var.region}${var.zone[2]}"
  enable_resource_name_dns_a_record_on_launch = true
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.project}-private-1"
    project = var.project
    env = var.env
  }
}

resource "aws_eip" "ngw" {

  vpc      = true
  tags = {
    Name = "${var.project}-${var.env}-ngw-eip"
    project = var.project
    env = var.env
  }
}

resource "aws_nat_gateway" "ngw" {

  count = var.project != "uber" ? 1:0
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.env}-ngw"
    project = var.project
    env = var.env
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project}-${var.env}-public"
    project = var.project
    env = var.env
  }
}

resource "aws_route_table" "private1" {

  count = var.project != "uber"? 1:0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name = "${var.project}-${var.env}-private"
    project = var.project
    env = var.env
  }
}

resource "aws_route_table" "private2" {

  count = var.project != "uber"? 0:1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-private"
    project = var.project
    env = var.env
  }
}

resource "aws_route_table_association" "public" {

  count = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private1" {
  
  count = var.project != "uber" ? 1:0
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private1[count.index].id
}

resource "aws_route_table_association" "private2" {
  
  count = var.project != "uber" ? 0:1
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private2[count.index].id
}