locals {
  lambda_function_name = "golang-lambda-by-terraform-executor"
}

module "iam" {
  source = "../module/iam"

  lambda_function_name = local.lambda_function_name
}

module "lambda" {
  source = "../module/lambda"

  lambda_function_name      = local.lambda_function_name
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
}

module "eventbridge" {
  source = "../module/eventbridge"

  lambda_function_name = local.lambda_function_name
  lambda_function_arn  = module.lambda.lambda_function_arn
}
