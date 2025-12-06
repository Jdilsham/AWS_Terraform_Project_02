variable "aws_rigion" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project Name"
  default     = "project-2"
}

variable "instance_type" {
  default = "t2.micro"
}

