# ==========================================
# PRIMARY S3 BUCKET
# ==========================================

resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = var.s3_bucket_primary

  tags = {
    Name        = "${var.project_name}-primary-assets"
    Environment = "production"
    Region      = var.primary_region
  }
}

# Enable versioning (required for replication)
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configure replication
resource "aws_s3_bucket_replication_configuration" "primary_to_secondary" {
  provider = aws.primary
  role     = aws_iam_role.s3_replication.arn
  bucket   = aws_s3_bucket.primary.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {}

    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.secondary
  ]
}

# ==========================================
#  SECONDARY S3 BUCKET
# ==========================================
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = var.s3_bucket_secondary

  tags = {
    Name        = "${var.project_name}-secondary-assets"
    Environment = "production"
    Region      = var.secondary_region
  }
}

# Enable versioning (required for replication)
resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id

  versioning_configuration {
    status = "Enabled"
  }
}

