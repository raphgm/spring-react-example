# Provider Configuration
provider "aws" {
  region = var.region
}

# Security Group for EC2 and MySQL
resource "aws_security_group" "devopssg" {
  name        = "devopssg"
  description = "Allow SSH and MySQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance Setup
resource "aws_instance" "devopstask_instance" {
  ami                = var.ami_id
  instance_type      = var.instance_type
  security_groups    = [aws_security_group.devopssg.name]

  tags = {
    Name = "devopstask-instance"
  }
}

# RDS Instance Setup (DevOps DB)
resource "aws_db_instance" "devopsdb" {
  allocated_storage      = var.db_allocated_storage
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.db_instance_class
  identifier             = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.devopssg.id]

  tags = {
    Name = "DevOpsDB"
  }
}

# CloudWatch Metrics Alarm for RDS CPU
resource "aws_cloudwatch_metric_alarm" "rds_cpu_alarm" {
  alarm_name          = "RDS-CPU-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300 # 5-minute intervals
  statistic           = "Average"
  threshold           = 80 # Trigger alarm if CPU > 80%

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.devopsdb.id
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
  ok_actions    = [aws_autoscaling_policy.scale_in_policy.arn]
}

# CloudWatch Logs for EC2 Instance
resource "aws_cloudwatch_log_group" "ec2_log_group" {
  name = "/aws/ec2/devopstask-instance-logs"
}

resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
  name           = "instance-logs"
}

# Auto Scaling Launch Configuration (defines the EC2 instance template)
resource "aws_launch_template" "devopstask_launch_template" {
  image_id        = var.ami_id
  instance_type   = var.instance_type
  vpc_security_group_ids = [aws_security_group.devopssg.id]
  key_name        = var.key_name

  lifecycle {
    create_before_destroy = true # Ensures a new launch configuration is created before the old one is destroyed
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "devopstask_asg" {
  desired_capacity     = 1
  max_size             = 5 # Maximum number of EC2 instances
  min_size             = 1 # Minimum number of EC2 instances
  vpc_zone_identifier  = var.subnet_ids
  launch_template {
    id      = aws_launch_template.devopstask_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "devopstask-instance"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true
  # estimated_instance_warmup  = 180  # New instances are assumed to warm up in 3 minutes
}

# Scale out policy (increase instance count)
resource "aws_autoscaling_policy" "scale_out_policy" {
  name               = "scale-out-policy"
  scaling_adjustment = 1 # Add 1 instance
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300 # Wait 5 minutes before scaling again

  autoscaling_group_name = aws_autoscaling_group.devopstask_asg.name
}

# Scale in policy (decrease instance count)
resource "aws_autoscaling_policy" "scale_in_policy" {
  name               = "scale-in-policy"
  scaling_adjustment = -1 # Remove 1 instance
  adjustment_type    = "ChangeInCapacity"
  cooldown           = 300 # Wait 5 minutes before scaling again

  autoscaling_group_name = aws_autoscaling_group.devopstask_asg.name
}

# CloudWatch Alarm for scaling
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EC2 CPU utilization"
  dimensions = {
    InstanceId = aws_instance.devopstask_instance.id
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn] # Scaling out when alarm triggers
  ok_actions    = [aws_autoscaling_policy.scale_in_policy.arn]  # Scaling in when CPU is back to normal
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "devops_dashboard" {
  dashboard_name = "devops-dashboard"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.devopstask_instance.id],
            [".", "DiskWriteOps", ".", aws_instance.devopstask_instance.id]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "us-east-1", // Ensure this matches your AWS region
          "title" : "EC2 Metrics"
        }
      },
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.devopsdb.id],
            [".", "FreeStorageSpace", ".", aws_db_instance.devopsdb.id]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "us-east-1"
        }
      }
    ]
  })
}

# Destroy provisioner
resource "null_resource" "destroy_provisioner" {
  provisioner "local-exec" {
    when    = "destroy"
    command = "echo 'Destroying resources...'"
  }
}


