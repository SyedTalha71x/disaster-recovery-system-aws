# 🛡️ Multi-Region Disaster Recovery System on AWS

> **Enterprise-grade fault-tolerant DR solution** with automated failover across two AWS regions — achieving **RPO < 1 min** and **RTO < 3 min**

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)

---

## 📌 Overview

This project implements a **production-ready Disaster Recovery (DR)** infrastructure on AWS using Infrastructure as Code (Terraform). It provides seamless business continuity by maintaining an **Active-Passive** architecture across two geographically separated regions — with automated failover via Cloudflare DNS health checks.

| Metric | Target | Achieved |
|--------|--------|----------|
| RPO (Recovery Point Objective) | < 1 minute | ✅ |
| RTO (Recovery Time Objective) | < 3 minutes | ✅ |
| Uptime SLA | 99.9% | ✅ |
| Total Resources Managed | 107+ | ✅ |
| Deployment Time | ~15 minutes | ✅ |

---

## 🏗️ Architecture

```
                        ┌─────────────────────┐
                        │    Cloudflare DNS    │
                        │   (Health Checks)    │
                        └──────────┬──────────┘
                                   │
               ┌───────────────────┴───────────────────┐
               │                                       │
    ┌──────────▼──────────┐               ┌────────────▼────────┐
    │   PRIMARY REGION    │               │  SECONDARY REGION   │
    │    us-east-1 🟢     │◄─────────────►│   ap-south-1 🟡     │
    │                     │  VPC Peering  │                     │
    │  ALB → EC2 (Multi-  │               │  ALB → EC2 (Multi-  │
    │  AZ) → RDS MySQL    │               │  AZ) → RDS Replica  │
    │  S3 (Primary)       │               │  S3 (Replica)       │
    └─────────────────────┘               └─────────────────────┘
```

### Active-Passive Failover Flow
- **Normal State:** All traffic routed to `us-east-1` (Primary)
- **Failure Detected:** Cloudflare health check fails on `/health` endpoint
- **Failover Triggered:** DNS automatically switches traffic to `ap-south-1` (Secondary)
- **Recovery:** Manual or automated failback once primary is restored

---

## ✨ Key Features

- **Active-Passive Architecture** — Primary region handles all live traffic; secondary stays warm as DR standby
- **Cross-Region Database Replication** — RDS MySQL with real-time cross-region read replicas
- **Automated DNS Failover** — Cloudflare health checks with zero-downtime region switching
- **Infrastructure as Code** — 107+ AWS resources fully automated via Terraform
- **Multi-AZ High Availability** — Redundant deployments within each region
- **End-to-End Encryption** — At-rest encryption for RDS and S3
- **Least-Privilege Security** — IAM roles scoped per service with VPC isolation

---

## 🧰 Tech Stack

### Cloud & Infrastructure
| Service | Purpose |
|---------|---------|
| AWS VPC | Multi-region isolated networking |
| AWS EC2 (t3.small) | Web application servers |
| AWS ALB | Traffic distribution across AZs |
| AWS RDS MySQL 8.0 | Database with cross-region replication |
| AWS S3 | Static assets with cross-region replication |
| AWS IAM | Service roles and least-privilege policies |
| AWS NAT Gateway | Outbound internet for private subnets |
| AWS CloudWatch | Monitoring, alarms, and logging |

### IaC & DevOps
| Tool | Purpose |
|------|---------|
| Terraform v1.x | Complete infrastructure automation |
| Remote State Backend | Centralized Terraform state management |
| Modular Configuration | Reusable, composable Terraform modules |

### Networking & DNS
| Component | Purpose |
|-----------|---------|
| Cloudflare DNS | Global traffic management & failover |
| Health Checks | Endpoint monitoring (`/health`) |
| VPC Peering | Secure cross-region private connectivity |

### Application
| Tool | Purpose |
|------|---------|
| Node.js | Web application runtime |
| PM2 | Process management & auto-restart |

---

## 📁 Project Structure

```
disaster-recovery-system/
├── application-code/           # Node.js web application
│   ├── server.js               # Main application server
│   ├── package.json
│   └── node_modules/
│
├── disaster-recovery-infrastructure/   # Terraform IaC
│   ├── main.tf                 # Root module
│   ├── providers.tf            # AWS provider config (multi-region)
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── backend.tf              # Remote state configuration
│   ├── vpc.tf                  # VPC, subnets, routing
│   ├── vpc-peering.tf          # Cross-region VPC peering
│   ├── ec2-instances.tf        # Web server instances
│   ├── load-balancers.tf       # ALB configuration
│   ├── rds.tf                  # RDS MySQL + read replicas
│   ├── s3.tf                   # S3 buckets
│   ├── s3-backup.tf            # S3 cross-region replication
│   ├── security-groups.tf      # Security group rules
│   ├── iam.tf                  # IAM roles and policies
│   ├── monitoring.tf           # CloudWatch alarms
│   ├── user-data/              # EC2 bootstrap scripts
│   └── env/                    # Environment-specific configs
│
└── documentation/              # Architecture docs & runbooks
```

---

## 🚀 Getting Started

### Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.x installed
- Cloudflare account with DNS zone configured
- SSH key pair created in both regions

### 1. Clone the Repository

```bash
git clone https://github.com/SyedTalha71x/disaster-recovery-system-aws
cd disaster-recovery-system
```

### 2. Configure Variables

```bash
cp env/terraform.tfvars.example env/terraform.tfvars
# Edit terraform.tfvars with your values
```

Key variables to configure:

```hcl
project_name     = 
primary_region   = 
secondary_region = 

instance_type        = 
key_name_primary     = 
key_name_secondary   = 

environment      = 

# VPC Configuration
primary_vpc_cidr   = 
secondary_vpc_cidr = 

# RDS Database Configuration
db_name           = 
db_username       = 
db_password       = 
db_instance_class = 


s3_bucket_primary   = 
s3_bucket_secondary = 

allowed_ssh_cidr = 

# Backup Configuration
backup_retention_days = 

# Monitoring
monitoring_email = ""
```

### 3. Initialize & Deploy

```bash
terraform init
terraform plan
terraform apply
```

> ⏱️ Full infrastructure provisions in approximately **15 minutes**

### 4. Verify Deployment

```bash
terraform output
# Check primary ALB DNS
curl http://<primary-alb-dns>/health
```

---

## 🔁 Disaster Recovery Testing

### Simulating Failover

1. **Trigger Primary Region Failure** — Stop EC2 instances or block ALB health checks in `us-east-1`
2. **Monitor Cloudflare** — Health check will detect failure within seconds
3. **DNS Failover** — Traffic automatically routes to `ap-south-1`
4. **Verify** — Access your domain and confirm secondary region is serving traffic

### Failback Procedure

1. Restore primary region resources
2. Verify `/health` endpoint returns `200 OK`
3. Cloudflare automatically fails back once health checks pass

---

## 📊 Monitoring

CloudWatch alarms are configured for:
- **CPU Utilization** — EC2 instances in both regions
- **Instance Status Checks** — Hardware and software health
- **RDS Replication Lag** — Cross-region replication delay
- **ALB Target Health** — Backend instance availability

Access logs and metrics via AWS CloudWatch console in both regions.

---

## 🔒 Security

- **VPC Isolation** — Databases in private subnets, no public access
- **Security Groups** — Least-privilege inbound/outbound rules
- **IAM Roles** — Service-specific roles, no shared credentials
- **Encryption at Rest** — RDS and S3 encryption enabled
- **SSH Access** — Key-pair authentication only

---

## 🧹 Cleanup

To destroy all infrastructure and avoid AWS charges:

```bash
terraform destroy
```

---

## 👤 Author

**Talha**
- Built with ❤️ as a DevOps engineering project
- Demonstrates enterprise-grade DR capabilities on AWS

