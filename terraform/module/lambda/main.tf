resource "aws_lambda_function" "default" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/archive/main.zip"
  role          = var.lambda_execution_role_arn
  handler       = "main"
  runtime       = "go1.x"
  source_code_hash = data.archive_file.default.output_base64sha256
  publish = true

  environment {
    variables = {
      SLACK_WEBHOOK_URL = "<write your slack webhook url>"
      COST_EXPLORE_URL = "https://us-east-1.console.aws.amazon.com/cost-management/home?region=ap-northeast-1#/dashboard"
      CLOUD_WATCH_URL = "https://ap-northeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-northeast-1#dashboards:"
    }
  }
}

resource "null_resource" "default" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "GOOS=linux GOARCH=amd64 go build -o ${path.module}/bin/main ../../main.go"
  }
}

data "archive_file" "default" {
  depends_on  = [null_resource.default]
  type        = "zip"
  source_file = "${path.module}/bin/main"
  output_path = "${path.module}/archive/main.zip"
}
