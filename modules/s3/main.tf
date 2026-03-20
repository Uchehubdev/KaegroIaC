# 1. Create the S3 Bucket
resource "aws_s3_bucket" "kaegro_files" {
  bucket = "${var.project_name}-${var.environment}-static-media-8x2a"
  
  # Allow Terraform to delete the bucket in dev/staging even if it contains files
  force_destroy = var.environment != "live"

  tags = {
    Name        = "${var.project_name}-${var.environment}-static-media"
    Environment = var.environment
  }
}

# 2. Turn off the default block that prevents public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.kaegro_files.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. Create a Bucket Policy that allows anyone to view the files
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.kaegro_files.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.kaegro_files.arn}/*"
      },
    ]
  })

  # Ensure the public block is removed before applying this policy
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# 4. CORS Configuration (Crucial for kaegro web fonts and JavaScript to load properly)
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.kaegro_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = ["*"] # For production, you can restrict this to "https://kaegro.com"
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}