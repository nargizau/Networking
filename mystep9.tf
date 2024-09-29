#Step 9: Monitoring and Notification (CloudWatch and SNS Setup)
#In this step, we'll set up AWS CloudWatch to monitor your infrastructure, including EC2 instances, RDS databases, and S3. We'll also configure AWS SNS (Simple Notification Service) to send out notifications when specific alarms are triggered. These notifications can be delivered via email or SMS to ensure you're immediately aware of any critical issues.

#Key Monitoring Metrics:
#EC2 Instances:
#CPU Utilization
#Disk Space Utilization
#Memory Usage (requires custom CloudWatch metrics)
#RDS Databases:
#CPU Utilization
#Free Storage Space
#Read/Write Latency
#S3 Bucket:
#Number of Requests
#Bucket Size
#S3 Glacier Transitions and Lifecycle Events:
#Transition events to Glacier and data lifecycle checks.
#Terraform Code for Step 9: CloudWatch Monitoring and SNS Notifications

provider "aws" {
  region = "us-west-1"
}

### SNS TOPIC CREATION ###

# Create an SNS topic for alerts
resource "aws_sns_topic" "infrastructure_alerts" {
  name = "infrastructure-alerts"
}

# Create SNS subscription (Email)
resource "aws_sns_topic_subscription" "email_alert_subscription" {
  topic_arn = aws_sns_topic.infrastructure_alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # Replace with your email address
}

# Create SNS subscription (SMS)
resource "aws_sns_topic_subscription" "sms_alert_subscription" {
  topic_arn = aws_sns_topic.infrastructure_alerts.arn
  protocol  = "sms"
  endpoint  = "+1234567890"  # Replace with your phone number
}

### CLOUDWATCH ALARMS FOR EC2 ###

# Create an alarm for EC2 instance high CPU usage
resource "aws_cloudwatch_metric_alarm" "high_cpu_ec2" {
  alarm_name          = "high-cpu-usage-ec2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # Trigger alarm if CPU usage is > 80%

  dimensions = {
    InstanceId = aws_instance.app_instance.id
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

# Create an alarm for EC2 low disk space (requires custom CloudWatch metric)
resource "aws_cloudwatch_metric_alarm" "low_disk_space_ec2" {
  alarm_name          = "low-disk-space-ec2"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"  # Trigger alarm if disk space utilization is < 10%

  dimensions = {
    InstanceId = aws_instance.app_instance.id
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

### CLOUDWATCH ALARMS FOR RDS ###

# Create an alarm for RDS instance high CPU usage
resource "aws_cloudwatch_metric_alarm" "high_cpu_rds" {
  alarm_name          = "high-cpu-usage-rds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # Trigger alarm if CPU usage > 80%

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_instance.id
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

# Create an alarm for RDS low free storage space
resource "aws_cloudwatch_metric_alarm" "low_free_storage_rds" {
  alarm_name          = "low-free-storage-rds"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000000000"  # Trigger alarm if free storage space < 5GB

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds_instance.id
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

### CLOUDWATCH ALARMS FOR S3 ###

# Create an alarm for S3 bucket size threshold
resource "aws_cloudwatch_metric_alarm" "high_s3_bucket_size" {
  alarm_name          = "high-s3-bucket-size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"  # Check once per day
  statistic           = "Average"
  threshold           = "1000000000"  # Trigger alarm if bucket size exceeds 1GB

  dimensions = {
    BucketName = aws_s3_bucket.backup_bucket.bucket
    StorageType = "StandardStorage"
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

# Create an alarm for S3 requests exceeding threshold
resource "aws_cloudwatch_metric_alarm" "high_s3_requests" {
  alarm_name          = "high-s3-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfRequests"
  namespace           = "AWS/S3"
  period              = "86400"  # Check once per day
  statistic           = "Sum"
  threshold           = "1000"  # Trigger alarm if more than 1000 requests in a day

  dimensions = {
    BucketName = aws_s3_bucket.backup_bucket.bucket
  }

  alarm_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]

  insufficient_data_actions = [
    aws_sns_topic.infrastructure_alerts.arn
  ]
}

