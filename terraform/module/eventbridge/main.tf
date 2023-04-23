resource "aws_cloudwatch_event_rule" "default" {
    name                = "${var.lambda_function_name}-rule"
    description         = "Fires every month"
    schedule_expression = "cron(0 0 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "default" {
    rule      = aws_cloudwatch_event_rule.default.name
    arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "default" {
    action        = "lambda:InvokeFunction"
    function_name = var.lambda_function_name
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.default.arn
}