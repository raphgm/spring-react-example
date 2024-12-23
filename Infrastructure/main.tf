variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0e1c5d8c23330dee3" # Updated to the new AMI ID
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the Auto Scaling group will launch instances"
  type        = list(string)
}

variable "db_name" {
  description = "The name of the RDS database"
  type        = string
  default     = "devopsdb"
}

variable "db_username" {
  description = "The username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The password for the RDS instance"
  type        = string
  default     = "password123"
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "The allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "key_name" {
  description = "The name of the key pair to use for the EC2 instance"
  type        = string
  default     = "my-key-pair"
}

# Provider Configuration
provider "aws" {
  region = var.region
}

# Security Group for EC2 and MySQL
resource "aws_security_group" "devopssg" {
  name        = "devopssg-unique" # Changed to a unique name
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
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.devopssg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "DevOpsTaskInstance"
    }
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
  allocated_storage    = var.db_allocated_storage
  engine               = "mysql"
  instance_class       = var.db_instance_class
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
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
  name           = "instance-logs"
  log_group_name = aws_cloudwatch_log_group.ec2_log_group.name
}

# Launch Template
resource "aws_launch_template" "devopstask_launch_template" {
  name_prefix   = "devopstask_launch_template_"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

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
  desired_capacity    = 1

  tag {
    key                 = "Name"
    value               = "DevOpsTaskInstance"
    propagate_at_launch = true
  }
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
          "region" : "us-east-1",
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
          "region" : "us-east-1",
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


