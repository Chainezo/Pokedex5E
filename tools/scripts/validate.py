from pathlib import Path
import json
import os

root = Path(__file__).parent.parent.parent / "assets" / "datafiles"
habitat_json = root / "habitat.json"
pokemons_json = root / "pokemon.json"
pokedex_extra_json = root / "pokedex_extra.json"
pokemon_order_json = root / "pokemon_order.json"
moves_json = root / "moves.json"
tm_json = root / "move_machines.json"
abilities_json = root / "abilities.json"
feats_json = root / "feats.json"

images_path = root.parent / "textures"


def pokedex_order():
    order = []
    indexes = []
    with open(pokemons_json, "r") as f:
        pokemon_data = json.load(f)
        for species, data in pokemon_data.items():
            if data["index"] not in indexes:
                indexes.append(data["index"])
                order.append(species)
    return order


def habitat():
    with open(habitat_json, "r") as fp:
        with open(pokemon_order_json, "r") as f:
            pokemon_data = json.load(f)
            habitat_data = json.load(fp)

            for _, pokemon_list in habitat_data.items():
                for poke in pokemon_list:
                    pokemon_data["number"].remove(poke)
            print(pokemon_data["number"])


def pokedex_extra():
    with open(pokedex_extra_json, "r", encoding="utf8") as fp:
        pokedex_extra_data = json.load(fp)

        for species in pokedex_order():
            try:
                pokedex_extra_data[species]
            except:
                print("Can't find", species)


def moves():
    with open(pokemons_json, "r") as fp:
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            pokemon_data = json.load(fp)
            
            for pokemon, data in pokemon_data.items():
                for move in data["Moves"]["Starting Moves"]:
                    if move not in move_data:
                        print(pokemon, "Starting move: ", move, "Invalid")
                for level, moves in data["Moves"]["Level"].items():
                    for move in moves:
                        if move not in move_data:
                            print(pokemon, "Level", level, "move: ", move, "Invalid")


def tm():
    with open(tm_json, "r") as fp:
        with open(moves_json, "r") as f:
            move_data = json.load(f)
            tm_data = json.load(fp)

            for num, move in tm_data.items():
                if not move in move_data:
                    print("Can't find TM: ", num, move)


def abilities():
    with open(pokemons_json, "r") as fp:
        with open(abilities_json, "r") as f:
            ability_data = json.load(f)
            pokemon_data = json.load(fp)

            for _, data in pokemon_data.items():
                for ability in data["Abilities"]:
                    if not ability in ability_data:
                        print("Can't find ability ", ability)
                if "Hidden Ability" in data and data["Hidden Ability"] not in ability_data:
                    print("Can't find hidden ability ", data["Hidden Ability"])


def images():
    with open(pokemons_json, "r") as fp:
        pokemon_data = json.load(fp)
        for p, data in pokemon_data.items():
            for x in ["pokemons", "sprites"]:
                file_path = images_path / x / "{}{}.png".format(data["index"], p)
                if not os.path.exists(file_path):
                    print("Can't find image: ", "{}{}.png".format(data["index"], p), "in", x)

moves()