terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Primary Region Provider

provider "aws" {
  alias  = "primary"
  region = var.primary_region


  default_tags {
    tags = {
      Project     = "Disaster-recovery"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }

}

# Secondary Region Provider

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region


  default_tags {
    tags = {
      Project     = "Disaster-recovery"
      Environment = "DR"
      ManagedBy   = "Terraform"
    }
  }

}
