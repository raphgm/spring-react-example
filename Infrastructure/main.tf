# Provider Configuration
provider "aws" {
  region = var.region
}

# Security Group for EC2 and MySQL
resource "aws_security_group" "devopssg" {
  name        = "devopssg-unique"  # Changed to a unique name
  description = "Security group for devops task"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.devopssg.name]

  tags = {
    Name = "devopstask-instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 80 &
              EOF
}

# RDS Instance Setup (DevOps DB)
resource "aws_db_instance" "devopsdb" {
  identifier           = "devopsdb-instance"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0.34"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  publicly_accessible  = true
  vpc_security_group_ids = [aws_security_group.devopssg.id]
  skip_final_snapshot  = true

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
  name              = "/aws/ec2/devopstask-instance-logs"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "ec2_log_stream" {
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
  name           = "instance-logs"
}

# Launch Template
resource "aws_launch_template" "devopstask_launch_template" {
  name_prefix     = "devopstask_launch_template_"
  image_id        = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name

  network_interfaces {
    security_groups = [aws_security_group.devopssg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "DevOpsTaskInstance"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "devopstask_asg" {
  launch_template {
    id      = aws_launch_template.devopstask_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = var.subnet_ids
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  tag {
    key                 = "Name"
    value               = "devopstask-instance"
    propagate_at_launch = true
  }
}

# Scale out policy (increase instance count)
resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1  # Add 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300  # Wait 5 minutes before scaling again

  autoscaling_group_name = aws_autoscaling_group.devopstask_asg.name
}

# Scale in policy (decrease instance count)
resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1  # Remove 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300  # Wait 5 minutes before scaling again

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

  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]  # Scaling out when alarm triggers
  ok_actions    = [aws_autoscaling_policy.scale_in_policy.arn]   # Scaling in when CPU is back to normal
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
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.devopstask_instance.id],
            [".", "NetworkOut", ".", aws_instance.devopstask_instance.id]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "us-east-1", // Ensure this matches your AWS region
          "title" : "EC2 Network Metrics"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "ec2_dashboard" {
  dashboard_name = "EC2-Dashboard"
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
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.devopstask_instance.id]
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
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.devopstask_instance.id],
            [".", "NetworkOut", ".", aws_instance.devopstask_instance.id]
          ],
          "period" : 300,
          "stat" : "Average",
          "region" : "us-east-1", // Ensure this matches your AWS region
          "title" : "EC2 Network Metrics"
        }
      }
    ]
  })
}

# Destroy provisioner
resource "null_resource" "destroy_provisioner" {
  provisioner "local-exec" {
    when    = "destroy"
    command = "echo 'Resource destroyed'"
  }
}


