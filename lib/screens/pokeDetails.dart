import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon_data.dart';

class PokemonDetailScreen extends StatefulWidget {
  final String name;
  final String image;
  final List<Pokemon>? pokemonList;

  const PokemonDetailScreen({
    super.key,
    required this.name,
    required this.image,
    this.pokemonList,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  bool isBookmarked = false;
  Future<List<Map<String, dynamic>>>? _evolutions;
  bool loading = false;
  String? pokemonName;
  String? pokemonImage;
  SharedPreferences? prefs;
  int? pokemonHeight;
  int? pokemonWeight;
  int? baseExperience;
  List<String>? abilities = [];

  @override
  void initState() {
    pokemonName = widget.name;
    pokemonImage = widget.image;
    getPrefs();
    _evolutions = fetchPossibleEvolutions(widget.name);
    super.initState();
  }

  getPrefs() async {
    List<String> bookmarkedNames = [];
    prefs = await SharedPreferences.getInstance();
    final keys = prefs!.getKeys();
    keys.map((name) {
      bookmarkedNames.add(name);
    }).toList();
    isBookmarked = bookmarkedNames.contains(pokemonName);
  }

  displayNewPokemon() {
    setState(() {
      loading = true;
    });
    final random = Random();
    var element =
        widget.pokemonList![random.nextInt(widget.pokemonList!.length)];
    _evolutions = fetchPossibleEvolutions(element.name);
    pokemonName = element.name;
    pokemonImage = element.image;
  }

  Future<List<Map<String, dynamic>>> fetchPossibleEvolutions(
      String pokemonName) async {
    final response = await http
        .get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokemonName/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final speciesUrl = data['species']['url'];
      final speciesResponse = await http.get(Uri.parse(speciesUrl));
      pokemonHeight = data['height'];
      pokemonWeight = data['weight'];
      baseExperience = data['base_experience'];
      abilities = data['abilities']
          .map<String>(
              (dynamic ability) => ability['ability']['name'] as String)
          .toList();

      if (speciesResponse.statusCode == 200) {
        final speciesData = jsonDecode(speciesResponse.body);
        final evolutionChainUrl = speciesData['evolution_chain']['url'];
        final evolutionChainResponse =
            await http.get(Uri.parse(evolutionChainUrl));

        if (evolutionChainResponse.statusCode == 200) {
          final evolutionChainData = jsonDecode(evolutionChainResponse.body);
          var chain = evolutionChainData['chain'];
          final evolutions = <Map<String, dynamic>>[];
          Map<String, dynamic>? requirements;
          while (chain != null) {
            final species = chain['species'];
            final name = species['name'];
            final evolutionData = {
              'name': name,
              'image':
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${species['url'].split('/')[6]}.png',
              'level': requirements?['min_level'] ?? '-',
              'item': requirements?['item']?['name'] ?? '-',
              'trigger': requirements?['trigger']?['name'] ?? '-',
              'gender': requirements?['gender'] == 1
                  ? 'Male'
                  : requirements?['gender'] == 2
                      ? 'Female'
                      : '-',
              'location': requirements?['location']?['name'] ?? '-',
            };
            evolutions.add(evolutionData);

            requirements = chain['evolution_details'].isEmpty
                ? null
                : chain['evolution_details'][0];

            if (chain['evolves_to'].isEmpty) {
              break;
            } else {
              chain = chain['evolves_to'][0];
            }
          }
          setState(() {
            loading = false;
          });
          return evolutions;
        }
      }
    }
    setState(() {
      loading = false;
    });
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pokemonName!),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () async {
              setState(() {
                isBookmarked = !isBookmarked;
                if (isBookmarked) {
                  prefs?.setString(widget.name, widget.image);
                } else {
                  prefs?.remove(widget.name);
                }
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            loading
                ? const Center(
                    child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ))
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: _evolutions,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            children: [
                              Image.network(
                                pokemonImage!,
                                fit: BoxFit.cover,
                                height: 100,
                                width: 100,
                              ),
                              Text(
                                'Height: ${pokemonHeight! / 10} m',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Weight: ${pokemonWeight! / 10} kg',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Base experience: $baseExperience',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Abilities:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: abilities!
                                    .map((ability) => Text(
                                          '- $ability',
                                          style: const TextStyle(fontSize: 16),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Evolution chain ',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data?.length,
                                itemBuilder: (context, index) {
                                  final evolution = snapshot.data![index];
                                  return ListTile(
                                    leading: Image.network(
                                      evolution['image'],
                                      width: 100,
                                      height: 100,
                                    ),
                                    title: Text(evolution['name']),
                                    subtitle: Row(
                                      children: [
                                        const Text('Trigger : '),
                                        evolution['trigger'] != '-'
                                            ? Text('${evolution['trigger']}')
                                            : const Text('??'),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                        evolution['level'] != '-'
                                            ? Text('${evolution['level']}')
                                            : Container(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    displayNewPokemon();
                                  },
                                  child: const Text('New Pokemon'),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
