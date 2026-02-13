import requests


def lambda_handler(event, context):
    print(event)
    # Consulta a PokeAPI para obter os dados de um Pokémon específico
    pokemon_name = event.get("pokemon_name", "pikachu")
    url = f"https://pokeapi.co/api/v2/pokemon/{pokemon_name}"
    with requests.get(url) as response:
        data = response.json()
    print(f"Dados do Pokémon {pokemon_name}: {data}")

    return {
        "statusCode": 200,
        "body": f"Dados do Pokémon {pokemon_name} obtidos com sucesso!",
    }
