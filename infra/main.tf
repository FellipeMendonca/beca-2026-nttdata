module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  # function_name = "beca-2026-lambda-pokeapi"
  function_name = var.lambda_function_name
  description   = "Lambda que consulta a PokeAPI e retorna os dados de um Pokémon específico."
  handler       = "index.lambda_handler"
  runtime       = "python3.12"

  layers = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python312:22"]

  source_path             = "../src/lambda"
  ignore_source_code_hash = true
  tags = {
    Name        = "beca-2026-lambda-pokeapi"
    Squad       = "Formação 2026"
    Company     = "NTT Data"
    Environment = var.environment
  }
}
