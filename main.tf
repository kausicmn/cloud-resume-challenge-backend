resource "aws_s3_bucket" "s3backend" {
  bucket = "tf-state-frontend"
}
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "mycloudtable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"

attribute {
  name="Id"
  type="S"
}
}
resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.basic-dynamodb-table.name
  hash_key   = aws_dynamodb_table.basic-dynamodb-table.hash_key
  item = <<ITEM
{
  "Id" :{"S": "cnt"},
  "value": {"N": "0"}
}
ITEM
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "cloudDynamoDB-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:GetItem","dynamodb:PutItem"]
    resources = [aws_dynamodb_table.basic-dynamodb-table.arn]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "clouddynamoDBpolicy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "test_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_function.zip"
  function_name = "cloud_resume_function"
  role          = aws_iam_role.role.arn
  handler = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime = "python3.10"
}
resource "aws_apigatewayv2_api" "example" {
  name          = "example-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = []
  }
}
resource "aws_apigatewayv2_stage" "example" {
  api_id = aws_apigatewayv2_api.example.id
  name   = "example-stage"
  auto_deploy = true
}
resource "aws_apigatewayv2_integration" "example" {
  api_id           = aws_apigatewayv2_api.example.id
  integration_type = "AWS_PROXY"
  integration_uri    = aws_lambda_function.test_lambda.invoke_arn
}
resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.example.id
  route_key = "ANY /example"
  target = "integrations/${aws_apigatewayv2_integration.example.id}"
}
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_apigatewayv2_api.example.execution_arn}/*/*"
}
  data "aws_acm_certificate" "issued" {
  domain   = var.certificate_issued_domain
} 
data "aws_route53_zone" "myzone" {
  name         = var.domain_name
}
resource "aws_apigatewayv2_domain_name" "example" {
  domain_name = var.api-gateway-subdomain

  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.issued.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}
resource "aws_apigatewayv2_api_mapping" "example" {
  api_id      = aws_apigatewayv2_api.example.id
  domain_name = aws_apigatewayv2_domain_name.example.id
  stage       = aws_apigatewayv2_stage.example.id
}
resource "aws_route53_record" "count" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = aws_apigatewayv2_domain_name.example.domain_name
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.example.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.example.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
