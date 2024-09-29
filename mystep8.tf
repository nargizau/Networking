#In Step 8, we’ll focus on S3 backup configuration for both your EC2 instances and RDS databases. This step includes setting up automated backup routines for storing data in Amazon S3 and leveraging Amazon S3 Glacier for long-term storage and archival.

#Step 8: S3 Backups and Glacier Archival Configuration
#This step involves:

#Creating an S3 bucket to store backups from both EC2 instances and RDS databases.
#Configuring EC2 backups (either manual or automated) to be stored in the S3 bucket.
#Configuring RDS automated backups and snapshot storage in the S3 bucket.
#Setting up a lifecycle policy to move older backups to S3 Glacier for long-term storage.
#Terraform Code for S3 Backup and Glacier Archival

provider "aws" {
  region = "us-west-1"
}

### S3 BUCKET CREATION ###

# Create S3 bucket for storing EC2 and RDS backups
resource "aws_s3_bucket" "backup_bucket" {
  bucket = "my-ec2-rds-backups"  # Make sure the bucket name is unique

  versioning {
    enabled = true  # Enable versioning for backup tracking
  }

  lifecycle_rule {
    id      = "move-to-glacier"
    enabled = true

    # Define rule to move objects to Glacier after 30 days
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # Define rule to permanently delete objects after 365 days
    expiration {
      days = 365
    }
  }
}

### BACKUPS FOR EC2 ###

# Create an IAM role for EC2 to allow access to S3
resource "aws_iam_role" "ec2_backup_role" {
  name = "ec2-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policy to allow the role to write backups to S3
resource "aws_iam_role_policy" "s3_backup_policy" {
  name = "s3-backup-policy"
  role = aws_iam_role.ec2_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Effect   = "Allow",
      Resource = [
        aws_s3_bucket.backup_bucket.arn,
        "${aws_s3_bucket.backup_bucket.arn}/*"
      ]
    }]
  })
}

# Attach the role to EC2 instance for backup access
resource "aws_iam_instance_profile" "ec2_backup_instance_profile" {
  name = "ec2-backup-instance-profile"
  role = aws_iam_role.ec2_backup_role.name
}

# Example EC2 instance creation
resource "aws_instance" "app_instance" {
  ami           = "ami-12345678"  # Replace with actual AMI ID
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_backup_instance_profile.name

  tags = {
    Name = "AppInstance"
  }
}

# Script to create EC2 snapshot and store it in S3
resource "aws_instance" "app_instance_backup_script" {
  user_data = <<-EOF
    #!/bin/bash
    # Create EC2 snapshot and upload to S3

    INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
    SNAPSHOT_ID=$(aws ec2 create-snapshot --volume-id vol-xxxxxxxx --description "EC2 Backup $TIMESTAMP" --output text --query SnapshotId)
    aws s3 cp /path/to/backup.zip s3://${aws_s3_bucket.backup_bucket.bucket}/ec2-backups/backup-${TIMESTAMP}.zip
  EOF
}

### BACKUPS FOR RDS ###

# Create an RDS snapshot manually (or this can be done automatically via AWS settings)
resource "aws_db_snapshot" "rds_backup" {
  db_instance_identifier = aws_db_instance.rds_instance.id
  db_snapshot_identifier = "rds-snapshot-${timestamp()}"
}

# Copy RDS snapshot to S3 bucket
resource "aws_s3_bucket_object" "rds_snapshot_backup" {
  bucket = aws_s3_bucket.backup_bucket.bucket
  key    = "rds-backups/rds-snapshot-${timestamp()}.snapshot"

  # Path to the RDS snapshot file, replace with actual path
  source = "/path/to/rds/snapshot/file"
}

### LIFECYCLE POLICIES FOR ARCHIVING ###

# Define a lifecycle policy to move old backups to Glacier
resource "aws_s3_bucket_lifecycle_configuration" "backup_lifecycle" {
  bucket = aws_s3_bucket.backup_bucket.bucket

  rule {
    id     = "MoveOldBackupsToGlacier"
    status = "Enabled"

    filter {
      prefix = "ec2-backups/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  rule {
    id     = "MoveOldRDSSnapshotsToGlacier"
    status = "Enabled"

    filter {
      prefix = "rds-backups/"
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

### IAM PERMISSIONS FOR RDS TO S3 ###

# RDS will require permissions to export its backups to S3
resource "aws_iam_role" "rds_backup_role" {
  name = "rds-backup-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })
}

# Attach policy to allow RDS to export backups to S3
resource "aws_iam_role_policy" "rds_s3_backup_policy" {
  name = "rds-s3-backup-policy"
  role = aws_iam_role.rds_backup_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      Effect   = "Allow",
      Resource = [
        aws_s3_bucket.backup_bucket.arn,
        "${aws_s3_bucket.backup_bucket.arn}/*"
      ]
    }]
  })
}
