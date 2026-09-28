data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "backend" {
  family                   = "techchallenge1-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                        = "512"
  memory                     = "1024"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com/techchallenge1-backend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_logs.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])

  tags = {
    Name = "techchallenge1-backend"
  }
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "techchallenge1-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                        = "512"
  memory                     = "1024"
  execution_role_arn        = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com/techchallenge1-frontend:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_logs.name
          "awslogs-region"        = "us-east-2"
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = {
    Name = "techchallenge1-frontend"
  }
}