import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_mini/screens/bookmarked.dart';
import 'dart:convert';
import 'package:pokedex_mini/screens/pokeDetails.dart';
import '../models/pokemon_data.dart';
import '../widgets/pokemon_card.dart';

class PokemonGrid extends StatefulWidget {
  const PokemonGrid({Key? key}) : super(key: key);

  @override
  State<PokemonGrid> createState() => _PokemonGridState();
}

class _PokemonGridState extends State<PokemonGrid> {
  List<Pokemon> _pokemonList = [];
  Pokemon? _randomPokemon;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _fetchPokemon(true);
  }

  Future<void> _fetchPokemon(bool firstVisit) async {
    final response = await http.get(Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=200&offset=$_offset'));
    final data = jsonDecode(response.body);
    final List<Pokemon> pokemonList = [];

    for (var pokemon in data['results']) {
      final id = int.parse(pokemon['url'].split('/')[6]);
      final name = pokemon['name'];
      final image =
          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
      pokemonList.add(Pokemon(id: id, name: name, image: image));
    }

    final random = Random();
    var element = pokemonList[random.nextInt(pokemonList.length)];

    setState(() {
      _pokemonList = pokemonList;
      _randomPokemon = element;
    });
    if (firstVisit) {
      _navigateToRandomPokemon();
    }
  }

  void _fetchNextPokemon() {
    setState(() {
      _offset += 200;
    });
    _fetchPokemon(false);
  }

  void _fetchPreviousPokemon() {
    if (_offset >= 200) {
      setState(() {
        _offset -= 200;
      });
      _fetchPokemon(false);
    }
  }

  void _navigateToRandomPokemon() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(
          name: _randomPokemon!.name,
          image: _randomPokemon!.image,
          pokemonList: _pokemonList,
        ),
      ),
    );
  }

  void _navigateToBookmarked() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookmarksScreen(
          pokemonList: _pokemonList,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Grid'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(7),
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              semanticChildCount: _pokemonList.length,
              childAspectRatio: 200 / 244,
              physics: const BouncingScrollPhysics(),
              children: _pokemonList.map((pokemon) {
                return PokemonCard(
                  id: pokemon.id!,
                  name: pokemon.name,
                  image: pokemon.image,
                  pokemonList: _pokemonList,
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _fetchPreviousPokemon,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _fetchNextPokemon,
                child: const Text('Next'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _navigateToBookmarked,
                child: const Text('Bookmarked'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
