resource "aws_security_group" "alb_sg" {
  name        = "techchallenge1-alb-sg"
  description = "Allow inbound HTTP traffic to the load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "Allow backend traffic from the internet"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techchallenge1-alb-sg"
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "techchallenge1-ecs-sg"
  description = "Allow inbound traffic from the load balancer only"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Allow traffic from the ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "techchallenge1-ecs-sg"
  }
}