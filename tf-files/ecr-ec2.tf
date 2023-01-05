/*This terraform file creates a Compose enabled Docker machine on EC2 Instance. 
  Docker Machine is configured to work with AWS ECR using IAM role, and also
  upgraded to AWS CLI Version 2 to enable ECR commands.
  Docker Machine will run on Amazon Linux 2 EC2 Instance with
  custom security group allowing HTTP(80) and SSH (22) connections from anywhere. 
*/

provider "aws" {
  region = "us-east-1"
    access_key = "AKIAQSWK73EB7ETOJB4H"
    secret_key = "6kQXJV9ckgkI3Iibsc1aSGNzpBwK46mGX6wDOUro"
  //  If you have entered your credentials in AWS CLI before, you do not need to use these arguments.
}

# resource "aws_subnet" "server" {
#   vpc_id            = data.aws_vpc.mern-vpc.id
#   availability_zone = "us-east-1"
#   cidr_block        = cidrsubnet(data.aws_vpc.mern-vpc.cidr_block, 4, 1)
# }

resource "aws_security_group" "mern-sec-gr" {
  name = "mern-sec-gr"
  vpc_id = data.aws_vpc.mern-vpc.id
  tags = {
    Name = "mern-sec-group"
  }
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port   = 27017
    protocol    = "tcp"
    to_port     = 27017
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "ec2ecrfullaccess" {
  name = "ecr_ec2_permission"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ecr-ec2_profile"
  role = aws_iam_role.ec2ecrfullaccess.name
}

variable "vpc_id" {
  default = "vpc-097b4d68a6a038566"
}

variable "subnet_id" {
  default = "subnet-0500e77294490ccea"
}
variable "publicsb_id" {
  default = "subnet-056f4a99a6fd32999"
}

data "aws_vpc" "mern-vpc" {
  id = var.vpc_id
}

data "aws_subnet" "database" {
  id = var.subnet_id
}
data "aws_subnet" "mern-server" {
  id = var.publicsb_id
}

resource "aws_instance" "mern-instance" {
  ami                  = "ami-0574da719dca65348"
  instance_type        = "t3a.medium"
  key_name          = "firstkey" # you need to change this line
  #vpc_id            = data.aws_vpc.mern-vpc.id
  subnet_id = data.aws_subnet.mern-server.id
  vpc_security_group_ids = [aws_security_group.mern-sec-gr.id]
    tags = {
    Name = "mern-ecr-instance"
  }
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = filebase64("user-data.sh")
  
}
resource "aws_instance" "MongoDB-instance" {
  ami                  = "ami-0574da719dca65348"
  instance_type        = "t3a.medium"
  key_name        = "firstkey" # you need to change this line
  #vpc_id            = data.aws_vpc.mern-vpc.id
  subnet_id = data.aws_subnet.database.id
  tags = {
    Name = "MongoDB-instance"
  }
  user_data = filebase64("mongodb-data.sh")
  
}




output "ec2-public-ip" {
  value = "http://${aws_instance.mern-instance.public_ip}"
}

output "ssh-connection" {
  value = "ssh -i ~/.ssh/firstkey.pem ec2-user@${aws_instance.mern-instance.public_ip}"
}