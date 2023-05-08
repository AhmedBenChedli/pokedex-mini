import 'package:flutter/material.dart';
import '../models/pokemon_data.dart';
import '../screens/pokeDetails.dart';

class PokemonCard extends StatelessWidget {
  final int id;
  final String name;
  final String image;
  final List<Pokemon> pokemonList;
  const PokemonCard(
      {super.key,
      required this.id,
      required this.name,
      required this.image,
      required this.pokemonList});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PokemonDetailScreen(
                name: name,
                image: image,
                pokemonList: pokemonList,
              ),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.network(
              image,
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '#$id',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
