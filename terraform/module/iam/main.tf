resource "aws_iam_role" "default" {
  name               = "${var.lambda_function_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = data.aws_iam_policy.default.arn
}

data "aws_iam_policy" "default" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "default" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
