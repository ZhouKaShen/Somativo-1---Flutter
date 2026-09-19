import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/consumed_provider.dart';
import '../widgets/character_grid_item.dart';
import 'detail_screen.dart';

class ConsumedScreen extends StatelessWidget {
  const ConsumedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistidos')),
      body: Consumer<ConsumedProvider>(
        builder: (context, consumedProvider, _) {
          final consumed = consumedProvider.consumed;
          if (consumed.isEmpty) {
            return const Center(
              child: Text('Você ainda não marcou nenhum personagem como assistido.'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: consumed.length,
            itemBuilder: (context, index) {
              final character = consumed[index];
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
