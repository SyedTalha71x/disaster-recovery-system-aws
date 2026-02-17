# Disaster Recovery Runbook

## Recovery Time Objectives (RTO):
- Web Tier: 2-5 minutes (DNS propagation)
- Database: 5-10 minutes (manual promotion)
- Application: 1-2 minutes (configuration update)

## Recovery Point Objectives (RPO):
- Database: < 60 seconds (async replication lag)
- S3: < 5 minutes (cross-region replication)

## Failover Procedures:

### Scenario 1: Primary Region Outage
1. Execute failover script: `./failover-to-secondary.sh`
2. Update Cloudflare DNS (manual)
3. Verify secondary application is working
4. Monitor metrics and logs

### Scenario 2: Database Failure Only
1. Promote secondary MySQL slave to master
2. Update primary web servers to use secondary DB
3. Monitor application

### Scenario 3: Partial Failure
1. Route traffic away from affected AZ
2. Scale up in healthy AZ
3. Investigate root cause

## Testing Procedures:
1. **Quarterly DR Drill**:
   - Simulate primary region failure
   - Execute failover procedure
   - Measure RTO/RPO
   - Failback when complete

2. **Monthly Component Tests**:
   - Test database failover
   - Test S3 replication
   - Test health checks