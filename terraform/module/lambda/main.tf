resource "aws_lambda_function" "default" {
  function_name = var.lambda_function_name
  filename      = "${path.module}/archive/main.zip"
  role          = var.lambda_execution_role_arn
  handler       = "main"
  runtime       = "go1.x"
  source_code_hash = data.archive_file.default.output_base64sha256
  publish = true
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
