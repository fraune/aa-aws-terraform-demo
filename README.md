# aa-aws-terraform-demo

## Requirements 📋

**Functional/Architectural Requirements:**
 
Deliver four backend endpoints (no front end, no HTML) that will be the start of user management for a new application.  The endpoints shall create, read, update, and delete new users.  The properties of a user object are left up to you. Enable appropriate authentication and validation on these endpoints. The user’s data shall be stored in DynamoDB with primary and sort keys named ‘_pk0’ and _’sk0’ respectively. Deployment of these APIs can be provided through your preferred Infrastructure-As-Code framework.
 
**Required AWS services:**
- API Gateway
- DynamoDB
 
**Prohibited AWS services:**
- Lambda
 
**All other AWS services optional per your design.**
 
**Deliveries:**
- IAC code to deploy.
- Instructions so we can deploy and test the solution.
- Postman file we can use to exercise the deployed endpoints

## Design 🔩

- DynamoDB module for user storage setup
    - [terraform-aws-modules/dynamodb-table/aws](https://registry.terraform.io/modules/terraform-aws-modules/dynamodb-table/aws/latest)
- API Gateway-DynamoDB CRUD integrations, via the "AWS" integration type
    - [aws_api_gateway_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration)
- API Gateway endpoint configurations, authorization via "AWS_IAM" over a Lambda authorizer as per requirements
    - [aws_api_gateway_method](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method)
- Cloudwatch logging setup for debugging
    - Various resources

## Testing 🧪

### Quick iterations
CLI for quickly reapplying terraform from scratch
```
terraform fmt && terraform init && terraform destroy -auto-approve && terraform apply -auto-approve
```

### Setup

1. Deploy the Terraform
    ```
    cd terraform
    terraform init && terraform apply
    ```
1. Copy the `invoke_url` Terraform output
1. Open Postman and start a new request
1. Paste in the URL
1. Log into AWS and create a new access key in IAM (or use an existing one)
1. In your Postman request, switch to the Authorization tab and select the `AWS Signature` type
1. Paste in the `AccessKey` and `SecretKey`
1. Continue with further setup described in one of the CRUD methods below

### GET (Read)

Get requests return all the users in the table.

- Request type is `GET`
- Request body is `none`
