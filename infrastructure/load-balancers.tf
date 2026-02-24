# ==========================================
# PRIMARY REGION ALB
# ==========================================

# Target Group - Primary
resource "aws_lb_target_group" "primary" {
  provider    = aws.primary
  name        = "${var.project_name}-primary-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-primary-tg"
  }
}

# Register primary web instance
resource "aws_lb_target_group_attachment" "primary" {
  provider         = aws.primary
  target_group_arn = aws_lb_target_group.primary.arn
  target_id        = aws_instance.primary_web.id
  port             = 3000
}

# Application Load Balancer - Primary
resource "aws_lb" "primary" {
  provider           = aws.primary
  name               = "${var.project_name}-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_alb.id]
  subnets = [
    aws_subnet.primary_public_1.id,
    aws_subnet.primary_public_2.id
  ]

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name = "${var.project_name}-primary-alb"
  }
}

# ALB Listener - Primary
resource "aws_lb_listener" "primary_http" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

# ==========================================
# SECONDARY REGION ALB
# ==========================================

# Target Group - Secondary
resource "aws_lb_target_group" "secondary" {
  provider    = aws.secondary
  name        = "${var.project_name}-secondary-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.secondary.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-secondary-tg"
  }
}

# Register secondary web instance
resource "aws_lb_target_group_attachment" "secondary" {
  provider         = aws.secondary
  target_group_arn = aws_lb_target_group.secondary.arn
  target_id        = aws_instance.secondary_web.id
  port             = 3000
}

# Application Load Balancer - Secondary
resource "aws_lb" "secondary" {
  provider           = aws.secondary
  name               = "${var.project_name}-secondary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_alb.id]
  subnets = [
    aws_subnet.secondary_public_1.id,
    aws_subnet.secondary_public_2.id
  ]

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name = "${var.project_name}-secondary-alb"
  }
}

# ALB Listener - Secondary
resource "aws_lb_listener" "secondary_http" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary.arn
  }
}