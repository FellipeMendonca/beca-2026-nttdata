module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = var.lambda_function_name
  description   = "Lambda que consulta a PokeAPI e retorna os dados de um Pokémon específico."
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 120
  memory_size   = 512

  layers = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python312:22"]

  source_path             = "../src/lambda"
  ignore_source_code_hash = true
  tags = {
    Name        = "beca-2026-pokeapi-etl"
    Squad       = "Formação 2026"
    Company     = "NTT Data"
    Environment = var.environment
  }
}


resource "aws_s3_bucket" "pokeapi_bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "beca-2026-pokeapi-etl"
    Squad       = "Formação 2026"
    Company     = "NTT Data"
    Environment = var.environment
  }
}

module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = var.step_function_name
  definition = <<EOF
{
  "Comment": "ETL responsável por orquestrar a execução da função Lambda e dos jobs do Glue para processar os dados da PokeAPI.",
  "StartAt": "Get Data",
  "States": {
    "Get Data": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "ResultPath": "$.lambda_output",
      "Parameters": {
        "FunctionName": "${var.lambda_function_name}",
        "Payload": {}
      },
      "End": true
    }
  }
}
EOF
  tags = {
    Name        = "beca-2026-pokeapi-etl"
    Squad       = "Formação 2026"
    Company     = "NTT Data"
    Environment = var.environment
  }
}
