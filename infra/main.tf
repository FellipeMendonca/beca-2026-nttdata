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


resource "aws_s3_object" "lz_bronze_gj_pokeapi_etl_script" {
  bucket = aws_s3_bucket.pokeapi_bucket.id
  key    = "jobs/etl_job.py"
  source = "jobs/etl_job.py"
}

resource "aws_iam_role" "glue_job_role" {
  name = "glue-job-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_glue_job" "lz_bronze_gj_pokeapi_etl" {
  name              = var.lz_bronze_glue_job_name_pokeapi
  description       = "Glue responsável por processar os dados da LZ para Bronze transformando em um formato otimizado para análise e consulta."
  role_arn          = aws_iam_role.glue_job_role.arn
  glue_version      = "5.0"
  max_retries       = 0
  timeout           = 2880
  number_of_workers = 10
  worker_type       = "G.1X"
  execution_class   = "STANDARD"

  command {
    script_location = "s3://${aws_s3_bucket.pokeapi_bucket.bucket}/jobs/etl_job.py"
    name            = "glueetl"
    python_version  = "3"
  }

  notification_property {
    notify_delay_after = 3 # delay in minutes
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
  }

  execution_property {
    max_concurrent_runs = 1
  }

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


