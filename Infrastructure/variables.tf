variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0e1c5d8c23330dee3"
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