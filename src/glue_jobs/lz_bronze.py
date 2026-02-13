import sys
import boto3
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame

# Initialize Glue and Spark contexts
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Define source and destination S3 buckets
source_bucket = "s3://dev-us-east-1-beca-2026-bucket-pokeapi /LZ/pokemon_data.json"
destination_bucket = (
    "s3://dev-us-east-1-beca-2026-bucket-pokeapi/BRONZE/pokemon_data.parquet"
)

# Initialize S3 client
s3 = boto3.client("s3")


def delete_s3_files(bucket_name, prefix):
    """Deletes existing Parquet files in the specified S3 bucket and prefix."""
    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=prefix)
    if "Contents" in response:
        for obj in response["Contents"]:
            s3.delete_object(Bucket=bucket_name, Key=obj["Key"])
        print(f"All files deleted from {bucket_name}/{prefix}")
    else:
        print(f"No files found in {bucket_name}/{prefix}")


def main():
    try:
        # Delete existing files in destination bucket before writing new ones
        delete_s3_files("dev-us-east-1-beca-2026-bucket-pokeapi ", "BRONZE/")

        # Read JSON data from S3
        pokemon_df = spark.read.json(source_bucket)
        dynamic_frame = DynamicFrame.fromDF(pokemon_df, glueContext, "pokemon_df")

        # Write data as Parquet back to S3
        glueContext.write_dynamic_frame.from_options(
            frame=dynamic_frame,
            connection_type="s3",
            connection_options={"path": destination_bucket, "partitionKeys": []},
            format="parquet",
            format_options={"compression": "snappy"},  # Enables compression
        )

        print("JSON to Parquet conversion complete!")

        # Return success response
        return {"statusCode": 200, "body": "ETL job completed successfully."}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {"statusCode": 500, "body": f"ETL job failed: {str(e)}"}


# Run main function
main()
