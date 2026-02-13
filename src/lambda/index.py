import json
import requests
import boto3


def lambda_handler(event, context):
    url = "https://pokeapi.co/api/v2/pokemon/"
    pokemon_list = []
    s3 = boto3.client("s3")
    bucket_name = "dev-beca-2026-nttdata-pokeapi"
    file_name = "LZ/pokemon_data.json"

    for i in range(1, 152):  # Loop to get first 151 Pokémon
        response = requests.get(url + str(i))
        if response.status_code == 200:
            data = response.json()
            pokemon_list.append(
                {
                    "id": data["id"],
                    "name": data["name"],
                    "height": data["height"],
                    "weight": data["weight"],
                    "types": [t["type"]["name"] for t in data["types"]],
                    "stats": {s["stat"]["name"]: s["base_stat"] for s in data["stats"]},
                    "abilities": [a["ability"]["name"] for a in data["abilities"]],
                }
            )
        else:
            return {
                "statusCode": response.status_code,
                "body": json.dumps({"error": "Failed to fetch data"}),
            }

    # Save data to S3
    s3.put_object(Bucket=bucket_name, Key=file_name, Body=json.dumps(pokemon_list))

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Data saved to S3", "file": file_name}),
    }
