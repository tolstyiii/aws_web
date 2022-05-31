######################################################
# NLB
######################################################
resource "aws_lb" "nlb" {
  name                             = "bastion-lb"
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = aws_subnet.public.*.id
  enable_cross_zone_load_balancing = true
  tags                             = var.tags
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = "22"

  default_action {
    target_group_arn = aws_lb_target_group.nlb.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "nlb" {
  name     = "ssh"
  protocol = "TCP"
  port     = 22
  vpc_id   = aws_vpc.this.id

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "30"
    protocol            = "TCP"
    port                = "22"
  }

  tags = var.tags
}

######################################################
# Scaling group
######################################################

resource "aws_key_pair" "generated_key" {
  key_name   = "test-key"
  public_key = var.ssh_public_key

  lifecycle {
    ignore_changes = [
      public_key
    ]
  }
}

resource aws_placement_group this {
  name     = "web"
  strategy = "spread"
}

data aws_ami amazon-linux {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-ebs"]
  }
}

resource aws_launch_configuration this {
  name_prefix     = var.vm_name
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.private.id]

  associate_public_ip_address = false

  user_data = <<-EOF
#!/bin/bash
sudo su
yum update -y
yum install httpd -y
echo 'Hello MC! You are in )' > /var/www/html/index.html
service httpd start
EOF

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_lb.alb,
    aws_lb.nlb
  ]
}

resource aws_autoscaling_group this {
  name = var.vm_name
  min_size = 1
  max_size = 2
  desired_capacity = 1
  launch_configuration = aws_launch_configuration.this.name
  vpc_zone_identifier = aws_subnet.private.*.id
  target_group_arns = [aws_lb_target_group.nlb.arn, aws_lb_target_group.web.arn]

  health_check_type = "ELB"

  lifecycle {
    ignore_changes = [launch_configuration, tags, ]
  }

  tags = [
    {
      "key" = "Name of ASG"
      "value" = "${var.vm_name}"
      "propagate_at_launch" = true
    }
  ]
}

resource "aws_autoscaling_policy" "web_policy_up" {
  name = "web_policy_up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_up" {
  alarm_name = "web_cpu_alarm_up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [aws_autoscaling_policy.web_policy_up.arn]
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [aws_autoscaling_policy.web_policy_down.arn]
}

# resource "aws_autoscaling_attachment" "nlb" {
#   target_group_arn = aws_lb_target_group.nlb.arn
#   target_id        = aws_autoscaling_group.this
#   port             = 22
# }

####################################################
# ALB
####################################################

resource aws_lb_target_group web {
  name = "web"
  port = 80
  target_type = "instance"
  protocol = "HTTP"
  vpc_id = aws_vpc.this.id
}

# resource aws_alb_target_group_attachment web {
#   count            = length(aws_instance.web.*.id)
#   target_group_arn = aws_lb_target_group.web.arn
#   target_id        = aws_autoscaling_group.this.id
# }

resource aws_lb alb {
  name = "ALB"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.public.id]
  subnets = aws_subnet.public.*.id
}

resource aws_lb_listener http {
  load_balancer_arn = aws_lb.alb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource aws_lb_listener_rule static {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn

  }

  condition {
    path_pattern {
      values = ["/var/www/html/index.html"]
    }
  }
}