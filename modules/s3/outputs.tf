output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.kaegro_files.bucket
}

output "bucket_domain_name" {
  description = "The domain name of the S3 bucket"
  value       = aws_s3_bucket.kaegro_files.bucket_regional_domain_name
}