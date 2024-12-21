variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"  # Change to your preferred region
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-01816d07b1128cd2d"  # Change to your preferred AMI ID
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
  default     = "devopsdb"  # Ensure this conforms to RDS requirements
  validation {
    condition     = length(var.db_name) <= 64 && !regex("[^a-zA-Z0-9]", var.db_name)
    error_message = "The db_name must be a maximum of 64 characters and contain no special characters."
  }
}

variable "db_username" {
  description = "The username for the RDS instance"
  type        = string
  default     = "admin"  # Ensure this conforms to RDS requirements
  validation {
    condition     = length(var.db_username) >= 1 && length(var.db_username) <= 16 && !regex("[^a-zA-Z0-9]", var.db_username)
    error_message = "The db_username must be between 1 and 16 alphanumeric characters with no special characters."
  }
}

variable "db_password" {
  description = "The password for the RDS instance"
  type        = string
  default     = "Password123!"  # Ensure this conforms to RDS requirements
  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41 && regex("[A-Z]", var.db_password) && regex("[a-z]", var.db_password) && regex("[0-9]", var.db_password) && regex("[^a-zA-Z0-9]", var.db_password)
    error_message = "The db_password must be between 8 and 41 characters and contain at least one uppercase letter, one lowercase letter, one number, and one special character."
  }
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