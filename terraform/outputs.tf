output "invoke_url" {
  value = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.api_gateway_deployment.stage_name}/user"
}
