## Probably unnecessary response templates
```
resource "aws_api_gateway_method_response" "user_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = "200"

  #   response_models = {
  #     "application/json" = "Empty"
  #   }
}

resource "aws_api_gateway_integration_response" "dynamodb_get_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.user_resource.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = aws_api_gateway_method_response.user_get_200.status_code

  #   response_templates = {
  #     "application/json" = jsonencode({
  #       result = "$input.path('$')"
  #     })
  #   }
}
```
