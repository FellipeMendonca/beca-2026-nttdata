import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.window import Window
from pyspark.sql.functions import col, desc, rank

# Initialize Glue and Spark contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Define source and destination S3 buckets
source_bucket = "s3://dev-us-east-1-beca-2026-bucket-pokeapi/SILVER/pokemon_data.parquet"  # Replace with actual bucket
destination_bucket = "s3://dev-us-east-1-beca-2026-bucket-pokeapi/GOLD/pokemon_data.parquet"  # Replace with actual bucket

# Initialize S3 client
s3 = boto3.client("s3")

def delete_s3_files(bucket_name):
    response = s3.list_objects_v2(Bucket=bucket_name)
    if "Contents" in response:
        for obj in response["Contents"]:
            if "GOLD/pokemon_data.parquet" in obj["Key"]:
                s3.delete_object(Bucket=bucket_name, Key=obj["Key"])
        print(f"All files deleted from {bucket_name}")
    else:
        print(f"No files found in {bucket_name}")

# Delete existing files in destination bucket before writing new ones
delete_s3_files("dev-us-east-1-beca-2026-bucket-pokeapi")

# Read Parquet data from S3
pokemon_df = spark.read.parquet(source_bucket)
pokemon_df.printSchema()

# Use Window functions to rank Pokémon by base_stats within each primary_type
window_spec = Window.partitionBy("primary_type").orderBy(desc("base_stats"))
pokemon_df = pokemon_df.withColumn("rank", rank().over(window_spec))
pokemon_df.printSchema()

# Filter to keep only the top 2 Pokémon per primary_type
pokemon_df = pokemon_df.filter(col("rank") <= 2).drop("rank")
pokemon_df.printSchema()

dynamic_frame = DynamicFrame.fromDF(pokemon_df, glueContext, "pokemon_df")

# Write data as Parquet back to S3
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    connection_options={"path": destination_bucket},
    format="parquet"
)

print("Parquet to Parquet transformation complete with base stats columns!")
