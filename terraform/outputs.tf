output "invoke_url" {
  value = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com/${var.stage}/user"
}
