resource "aws_ecs_service" "backend" {
  name            = "techchallenge1-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_tg.arn
    container_name    = "backend"
    container_port    = 8080
  }

  depends_on = [aws_lb_listener.backend_listener]

  tags = {
    Name = "techchallenge1-backend-service"
  }
}

resource "aws_ecs_service" "frontend" {
  name            = "techchallenge1-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name    = "frontend"
    container_port    = 80
  }

  depends_on = [aws_lb_listener.frontend_listener]

  tags = {
    Name = "techchallenge1-frontend-service"
  }
}