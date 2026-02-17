#!/bin/bash
set -e

echo "=== MySQL Backup Started ==="

BACKUP_DIR="/tmp/mysql-backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mysql-backup-${DATE}.sql.gz"
S3_BUCKET="${S3_BACKUP_BUCKET}" # Set via environment variable

mkdir -p $BACKUP_DIR

# Dump database
mysqldump -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

# Upload to S3
aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" "s3://${S3_BUCKET}/mysql-backups/${BACKUP_FILE}"

# Cleanup old local backups (keep last 3)
ls -t ${BACKUP_DIR}/*.sql.gz | tail -n +4 | xargs rm -f

# Cleanup old S3 backups (keep last 7 days)
aws s3 ls "s3://${S3_BUCKET}/mysql-backups/" | \
  awk '{print $4}' | \
  sort -r | \
  tail -n +8 | \
  while read file; do
    aws s3 rm "s3://${S3_BUCKET}/mysql-backups/${file}"
  done

echo "=== MySQL Backup Complete: ${BACKUP_FILE} ==="