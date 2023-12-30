############
# DynamoDB #
############

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

##################################
# IAM policy role and attachment #
##################################

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
          "dynamodb:Scan", # Used for GET
          # "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
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

######################
# Cloudwatch Logging #
######################

resource "aws_cloudwatch_log_group" "api_gateway_log_group" {
  name = "/aws/apigateway/AADemo_UserAPI"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_role.arn
}

####################
# HTTP API Gateway #
####################

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "AADemo_UserAPI"
  description = "API for CRUD operations on the User Table"
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration_response.dynamodb_get_200, # Required, or we'll get a "no APIs" error on first deploy
    aws_api_gateway_integration_response.dynamodb_post_200,
    aws_api_gateway_integration_response.dynamodb_delete_200,
  ]

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  # Force a new deploy on configuration changes
  description = "Deployment at ${timestamp()}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage
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

# Use for create and read
resource "aws_api_gateway_resource" "user_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "user"
}

# Use for update and destroy - TODO: Fix
# resource "aws_api_gateway_resource" "user_resource_pk_sk" {
#   rest_api_id = aws_api_gateway_rest_api.api_gateway.id
#   parent_id   = aws_api_gateway_resource.user_resource.id # Parent is the /user resource
#   path_part   = "{pk}/{sk}"
# }
