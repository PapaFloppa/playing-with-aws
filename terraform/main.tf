terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

data "aws_caller_identity" "current" {}

locals {
  account_id = ""
  region = "us-east-1"
}
#####SNS TOPIC
resource "aws_sns_topic" "Ec2AlertTopic" {
  name = "Ec2AlertTopic"
}


######EC2 INSTANCE
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "fakepi" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    application = "fakepi",
    name = "fakepi2"
  }
}

resource "aws_iam_access_key" "sumouser" {
  user = aws_iam_user.sumouser.name
}

#########LAMBDA ROLE

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "lambdarole" {
  name = "lambdarole"


   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    tag-key = "tag-value"
  }
}


resource "aws_iam_role_policy" "lambda_policy" {
  name = "test_policy"
  role = aws_iam_role.lambdarole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${local.region}:${local.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/EC2RestartLambda:*"
            ]
        },
        {
            "Sid": "ec2allowreboot",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances"
            ],
            "Resource": [
                "${aws_instance.fakepi.arn}"
            ]
        },
        {
            "Sid": "ec2allowdescribe",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "allowsns",
            "Effect": "Allow",
            "Action": [
                "sns:publish"
            ],
            "Resource": [
                "arn:aws:sns:${local.region}:${local.account_id}:${aws_sns_topic.Ec2AlertTopic.name}"
            ]
        }
    ]
  })
}

#### LAMBDA FUNCTION
data "archive_file" "lambda_file" {
  type        = "zip"
  source_file = "/home/quade/repos/playing-with-aws/lambda_function/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}
# Lambda function
resource "aws_lambda_function" "EC2RestartLambda" {
  filename = data.archive_file.lambda_file.output_path
  function_name = "EC2RestartLambda"
  role          = aws_iam_role.lambdarole.arn
  handler       = "lambda_function.lambda_handler"

  runtime = "python3.14"

  tags = {
    Environment = "infra"
    Application = "fakepi"
  }
}
####LAMBDA URL
resource "aws_lambda_function_url" "example" {
  function_name      = aws_lambda_function.EC2RestartLambda.function_name
  authorization_type = "AWS_IAM"
  invoke_mode        = "RESPONSE_STREAM"
}

#######SUMO USER

resource "aws_iam_user" "sumouser" {
  name = "sumo.user"
}


resource "aws_iam_user_policy" "sumo_user" {
  name = "sumo_policy"
  user = aws_iam_user.sumouser.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction*",
        ]
        Effect   = "Allow"
        #TODO: put resource here
        Resource = "${aws_lambda_function.EC2RestartLambda.arn}"
      },
    ]
  })
}