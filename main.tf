#Default VPC and Subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#Security Group Module (From Terraform Registry)

module "web_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.project_name}-sg"
  description = "Security group for ${var.project_name} web servers"
  vpc_id      = data.aws_vpc.default.id

  #Allow inbound HTTP and SSH traffic
  ingress_rules       = ["http-80-tcp", "ssh-22-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  #Allow all outbound traffic
  egress_rules = ["all-all"]

}

#EC2 Instance Module (From Terraform Registry)

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}


#EC2 Instance

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                   = "${var.project_name}-ec2"
  instance_type          = var.instance_type
  ami                    = data.aws_ami.amazon_linux_2.id
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [module.web_sg.security_group_id]

  # Install and start Apache automatically
  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install -y httpd
        systemctl enable httpd
        systemctl start httpd
        echo "<h1>Hello from Terraform EC2 Instance!</h1>" > /var/www/html/index.html
    EOF

  tags = {
    Name = "${var.project_name}-ec2"
  }
}


#S3 Bucket Module (From Terraform Registry)

module "s3_website" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.project_name}-website-bucket"

  # Enable static website hosting
  website = {
    index_document = "index.html"
  }

  acl           = "public-read"
  force_destroy = true

  #Allow public read access
  attach_policy = true
  policy = jsonencode({
    version = "2012-10-17"
    statement = [
      {
        sid       = "PublicRead"
        effect    = "Allow"
        principal = "*"
        action    = ["s3:GetObject"]
        resource  = "arn:aws:s3:::${var.project_name}-website-bucket/*"
      }
    ]
  })

}

resource "aws_s3_object" "index" {
  bucket       = module.s3_website.s3_bucket_id
  key          = "index.html"
  content      = "<h1>Hello from S3 Static Website!</h1>"
  content_type = "text/html"
}