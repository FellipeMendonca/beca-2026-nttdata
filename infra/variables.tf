variable "environment" {
  description = "Ambiente de execução"
  type        = string
}

variable "lambda_function_name" {
  description = "Nome da função Lambda"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}

variable "lz_bronze_glue_job_name_pokeapi" {
  description = "Nome do job do Glue para processar os dados da PokeAPI da LZ para Bronze"
  type        = string
}

variable "step_function_name" {
  description = "Nome da função Step Function"
  type        = string
}
