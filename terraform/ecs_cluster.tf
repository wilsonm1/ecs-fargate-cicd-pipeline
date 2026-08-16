resource "aws_ecs_cluster" "main" {
  name = "techchallenge1-cluster"

  tags = {
    Name = "techchallenge1-cluster"
  }
}

resource "aws_cloudwatch_log_group" "backend_logs" {
  name              = "/ecs/techchallenge1-backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/techchallenge1-frontend"
  retention_in_days = 7
}