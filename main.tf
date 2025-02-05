resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev-vpc"
    environment = "dev"
    managed  = "terraform"
  }
}

resource "aws_subnet" "dev_public_subnet" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.123.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name        = "dev-public"
    environment = "dev"
    managed  = "terraform"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name        = "dev-igw"
    environment = "dev"
    managed  = "terraform"
  }
}

resource "aws_route_table" "dev_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name        = "dev-rt"
    environment = "dev"
    managed  = "terraform"
  }
}

resource "aws_route" "dev_route" {
  route_table_id         = aws_route_table.dev_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dev_igw.id
}

resource "aws_route_table_association" "dev_public_assoc" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_rt.id
}

resource "aws_security_group" "dev_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    environment = "dev"
    managed  = "terraform"
  }
}

resource "aws_key_pair" "dev_auth" {
  key_name   = "devkey"
  public_key = file("~/.ssh/devkey.pub")
}

resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami           = data.aws_ami.dev_server_ami.id
  key_name               = aws_key_pair.dev_auth.id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  subnet_id              = aws_subnet.dev_public_subnet.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 8
  }

  tags = {
    Name        = "dev-node"
    environment = "dev"
    managed  = "terraform"
  }
}
