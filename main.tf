provider "aws" {
  region = "us-west-2"  # Replace with your desired region
}

resource "aws_lambda_function" "spring_app" {
  function_name = "my-spring-app"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "com.example.HelloWorldApplication::handleRequest"  # Replace with your actual handler class and method

  runtime = "java11"
  timeout = 10

  environment {
    variables = {
      SPRING_PROFILES_ACTIVE = "production"
    }
  }

  filename         = "/home/kali/test-dec-2022/target/spring-boot-app-1.0.0.jar"  # Replace with the path to your Spring Boot JAR
  source_code_hash = filebase64sha256("/home/kali/test-dec-2022/target/spring-boot-app-1.0.0.jar")
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.spring_app.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = aws_api_gateway_rest_api.api_gateway.execution_arn
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "MySpringAppAPI"
  description = "API Gateway for my Spring Boot application"
}

resource "aws_api_gateway_resource" "api_gateway_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "myspringapp"
}

resource "aws_api_gateway_method" "api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_gateway_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.api_gateway_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.spring_app.invoke_arn
}

resource "aws_api_gateway_method_response" "api_gateway_method_response" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = aws_api_gateway_method.api_gateway_method.http_method
  status_code   = "200"  # Add the desired status code for the method response
}
