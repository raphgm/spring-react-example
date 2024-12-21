output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.devopstask_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.devopstask_instance.public_ip
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling group"
  value       = aws_autoscaling_group.devopstask_asg.name
}

output "scale_out_policy_arn" {
  description = "The ARN of the scale out policy"
  value       = aws_autoscaling_policy.scale_out_policy.arn
}

output "scale_in_policy_arn" {
  description = "The ARN of the scale in policy"
  value       = aws_autoscaling_policy.scale_in_policy.arn
}

output "cloudwatch_dashboard_url" {
  description = "The URL of the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=devops-dashboard"
}

