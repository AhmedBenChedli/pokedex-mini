import 'package:flutter/material.dart';
import 'package:pokedex_mini/screens/pokeDetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pokemon_data.dart';

class BookmarksScreen extends StatefulWidget {
  final List<Pokemon>? pokemonList;
  const BookmarksScreen({
    super.key,
    this.pokemonList,
  });
  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  SharedPreferences? _prefs;
  List<Pokemon>? _bookmarks;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
        _bookmarks = _loadBookmarks();
      });
    });
  }

  List<Pokemon> _loadBookmarks() {
    final keys = _prefs!.getKeys();
    return keys.map((name) {
      final image = _prefs!.getString(name)!;
      return Pokemon(
        name: name,
        image: image,
      );
    }).toList();
  }

  void _removeBookmark(int index) {
    final pokemon = _bookmarks!.removeAt(index);
    _prefs!.remove(pokemon.name).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pokemon.name} removed from bookmarks.'),
          duration: const Duration(seconds: 1),
        ),
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: _bookmarks == null
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks!.isEmpty
              ? const Center(
                  child: Text('You have not bookmarked any Pokemon yet.'),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemCount: _bookmarks!.length,
                  itemBuilder: (context, index) {
                    final pokemon = _bookmarks![index];
                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PokemonDetailScreen(
                                name: pokemon.name,
                                image: pokemon.image,
                                pokemonList: widget.pokemonList,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                            alignment: AlignmentDirectional.bottomCenter,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeBookmark(index),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    pokemon.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Image.network(
                                    pokemon.image,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ]),
                      ),
                    );
                  },
                ),
    );
  }
}
