resource "aws_iam_role" "default" {
  name               = "${var.lambda_function_name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.execution_policy.arn
}


data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "execution_policy" {
  name = "${var.lambda_function_name}-execution-policy"
  policy = data.aws_iam_policy_document.execution_policy_document.json
}

data "aws_iam_policy_document" "execution_policy_document" {
  statement {
    effect = "Allow"
    resources = [ "*" ]
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ce:GetCostAndUsage"
    ]
  }
}