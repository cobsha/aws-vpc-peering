module "vpc" {
    count = 2
    source = "../module"
    region = var.region
    vpc_cidr = var.cidr[count.index]
    env = var.env
    project = var.project[count.index]
}

resource "aws_vpc_peering_connection" "peer" {
  peer_owner_id = var.aws_id
  peer_vpc_id   = module.vpc[1].vpc_id
  vpc_id        = module.vpc[0].vpc_id
  auto_accept   = true

  tags = {
    Name = "VPC Peering between zomato and uber"
  }
}

resource "aws_route" "zomatopub" {
  route_table_id            = module.vpc[0].public
  destination_cidr_block    = var.cidr[1]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  depends_on                = [aws_vpc_peering_connection.peer]
}

resource "aws_route" "zomatopriv" {
  route_table_id            = module.vpc[0].private_route_zomato[0]
  destination_cidr_block    = var.cidr[1]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  depends_on                = [aws_vpc_peering_connection.peer]
}

resource "aws_route" "uberpub" {
  route_table_id            = module.vpc[1].public
  destination_cidr_block    = var.cidr[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  depends_on                = [aws_vpc_peering_connection.peer]
}

resource "aws_route" "uberpriv" {
  route_table_id            = module.vpc[1].private_route_uber[0]
  destination_cidr_block    = var.cidr[0]
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  depends_on                = [aws_vpc_peering_connection.peer]
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file("key.pub")
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-${var.env}-"
  description = "Allow SSH inbound traffic"
  vpc_id      = module.vpc[1].vpc_id

  ingress {
    description      = "SSH Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "bastion-${var.env}-sg"
  }
  lifecycle {

    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend" {
  name_prefix = "frontend-${var.env}-"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = module.vpc[1].vpc_id

  ingress {
    description     = "SSH Access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    description      = "HTTP Traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "TLS from outside"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "frontend-${var.env}-sg"
    env     = var.env
  }
  lifecycle {

    create_before_destroy = true
  }
  depends_on = [aws_security_group.bastion]
}

resource "aws_security_group" "backend" {
  name_prefix = "backend-${var.env}-"
  description = "Allow mysql inbound traffic"
  vpc_id      = module.vpc[0].vpc_id

  ingress {
    description     = "SSH Access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks      = [module.vpc[1].public_cidr[0]]
  }

  ingress {
    description     = "MYSQL Access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks      = [module.vpc[1].public_cidr[1]]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name    = "backend-${var.env}-sg"
    env     = var.env
  }
  lifecycle {

    create_before_destroy = true
  }
  depends_on = [aws_security_group.frontend]
}

resource "aws_instance" "bastion" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = module.vpc[1].public_subnet[0]
  tags = {
    Name    = "bastion-${var.env}"
    env     = var.env
  }

}

resource "aws_instance" "frontend" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.frontend.id]
  subnet_id              = module.vpc[1].public_subnet[1]
  user_data              = file("wordpress.sh")
  tags = {
    Name    = "frontend-${var.env}"
    env     = var.env
  }

}

resource "aws_instance" "backend" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]
  subnet_id              = module.vpc[0].private_subnet
  user_data              = file("database.sh")
  tags = {
    Name    = "backend-${var.env}"
    env     = var.env
  }

}


resource "aws_route53_record" "wordpress" {
  zone_id = data.aws_route53_zone.r53.zone_id
  name    = "wordpress.${data.aws_route53_zone.r53.name}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.frontend.public_ip]
}

