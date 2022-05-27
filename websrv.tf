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
  name_prefix     = "websrv-"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
#   user_data       = file("user-data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_autoscaling_group this {
  name                 = var.vm_name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.this.name
  vpc_zone_identifier  = aws_subnet.private.*.id

  lifecycle {
    ignore_changes  = [launch_configuration,tags]
  }
}

