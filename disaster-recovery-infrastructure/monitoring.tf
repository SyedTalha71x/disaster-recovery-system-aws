# monitoring.tf (Updated for RDS monitoring)
# Replication Lag Alarm
resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  provider            = aws.secondary
  alarm_name          = "${var.project_name}-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "60"
  alarm_description   = "Replication lag exceeded 60 seconds"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.secondary.identifier
  }
}

# Primary DB CPU Alarm
resource "aws_cloudwatch_metric_alarm" "primary_db_cpu" {
  provider            = aws.primary
  alarm_name          = "${var.project_name}-primary-db-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Primary DB CPU > 80%"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.identifier
  }
}