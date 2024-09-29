# Security Groups Configuration
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "GoGreenALBSecurityGroup"
  }
}
 
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id
 
     ingress {
     from_port   = 80
     to_port     = 80
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"] # Or more restricted
   }
   
   ingress {
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"] # Or more restricted
   }
   
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "GoGreenAppSecurityGroup"
  }
}
 
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main.id
 
  ingress {
    from_port   = 3306  # Adjust for your DB type
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "GoGreenDBSecurityGroup"
  }
}