########
# Setup
########

provider "aws" {
  region = "us-east-1"
}

variable "region" {
  description = "The region of the application"
  type        = string
  default     = "us-east-1"
}

variable "stage" {
  description = "The name of the stage"
  type        = string
  default     = "dev"
}

###########
# DynamoDB
###########

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "4.0.0"

  name      = "AADemo_UserTable"
  hash_key  = "_pk0"
  range_key = "_sk0"

  attributes = [
    {
      name = "_pk0"
      type = "S"
    },
    {
      name = "_sk0"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Application = "AA Demo"
    Environment = var.stage
  }
}

#################################
# IAM Policy role and attachment
#################################

resource "aws_iam_role" "api_gateway_dynamodb_role" {
  name = "api_gateway_dynamodb_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_dynamodb_policy" {
  name = "api_gateway_dynamodb_policy"
  role = aws_iam_role.api_gateway_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ],
        Effect   = "Allow",
        Resource = module.dynamodb_table.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role" "api_gateway_cloudwatch_role" {
  name = "api_gateway_cloudwatch_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      },
    ]
  })
}

#####################
# Cloudwatch Logging
#####################

resource "aws_iam_role_policy" "api_gateway_cloudwatch_policy" {
  name = "api_gateway_cloudwatch_policy"
  role = aws_iam_role.api_gateway_cloudwatch_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/apigateway/AADemo_UserAPI"
}

resource "aws_api_gateway_stage" "example_stage" {
  stage_name    = aws_api_gateway_deployment.api_gateway_deployment.stage_name # "api_gateway_deployment"
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.api_gateway_deployment.id

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_log_group.arn
    format = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      caller         = "$context.identity.caller",
      user           = "$context.identity.user",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  #   depends_on = [
  #     aws_api_gateway_integration.dynamodb_get,
  #     aws_api_gateway_account.example,
  #   ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  # The stage name is defined here and it should match with the aws_api_gateway_stage resource
  stage_name = "api_gateway_deployment"

  # This description encourages a new deployment on configuration changes
  description = "Deployment at ${timestamp()}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_method_settings" "example_settings" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.example_stage.stage_name
  method_path = "${aws_api_gateway_resource.user_resource.path_part}/${aws_api_gateway_method.user_get.http_method}"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_account" "example" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

###################
# HTTP API Gateway
###################

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "AADemo_UserAPI"
  description = "API for CRUD operations on the User Table"
}

resource "aws_api_gateway_resource" "user_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "user"
}

resource "aws_api_gateway_method" "user_get" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.user_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "dynamodb_get" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.user_resource.id
  http_method             = aws_api_gateway_method.user_get.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.region}:dynamodb:action/Scan"
  credentials             = aws_iam_role.api_gateway_dynamodb_role.arn

  request_templates = {
    "application/json" = jsonencode({
      TableName = "AADemo_UserTable",
      "version" : "2018-05-29",
      #   "operation" : "Scan"
    })
  }
}

resource "aws_api_gateway_method_response" "user_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = "200" # Adjust according to your API's response

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "dynamodb_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = aws_api_gateway_method_response.user_get_200.status_code
  depends_on = [
    aws_api_gateway_integration.dynamodb_get
  ]

  response_templates = {
    "application/json" = jsonencode({
      result = "$input.path('$')"
    })
  }
}
