import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/character_grid_item.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      // RF05 — reconstrói automaticamente quando o Provider muda
      // (ex: ao desfavoritar um item, ele some da lista na hora).
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, _) {
          final favorites = favoritesProvider.favorites;
          if (favorites.isEmpty) {
            return const Center(child: Text('Você ainda não tem favoritos.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final character = favorites[index];
              return CharacterGridItem(
                character: character,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(characterId: character.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
