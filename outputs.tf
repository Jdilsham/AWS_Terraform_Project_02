output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "The public DNS of the EC2 instance"
  value       = module.ec2_instance.public_dns
}

output "s3_website_url" {
  value = module.s3_website.s3_bucket_website_endpoint
}
