
resource "aws_instance" "example" {
    instance_type = "t2.microzzz"
    ami = var.instance_ami
    subnet_id              = aws_subnet.a_subnet.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    monitoring             = true

    metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_vpc" "new_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }
}

resource "aws_subnet" "a_subnet" {
  vpc_id            = aws_vpc.new_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "1a"

  tags = {
    Name = "Private Subnet Project VPC"
  }
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.new_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.5.7.0/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.5.7.0/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "example" {
  iam_role_arn    = aws_iam_role.example.arn
  log_destination = aws_cloudwatch_log_group.example.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.new_vpc.id
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "example"
  retention_in_days = 30
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "example" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  name   = "example"
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}