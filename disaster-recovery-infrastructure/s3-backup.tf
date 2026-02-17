
resource "aws_s3_bucket" "backup" {
  provider = aws.primary
  bucket   = "${var.project_name}-backup-${random_id.backup.hex}"

  tags = {
    Name        = "${var.project_name}-backup"
    Environment = "backup"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_id" "backup" {
  byte_length = 8
}

resource "aws_s3_bucket_versioning" "backup" {
  provider = aws.primary
  bucket   = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  provider = aws.primary
  bucket   = aws_s3_bucket.backup.id

  rule {
    id     = "backup-retention"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}