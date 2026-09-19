import 'package:flutter/material.dart';
import '../models/character.dart';

/// Card de personagem usado na grade do catálogo e na lista de
/// favoritos/consumidos. Trata imagem ausente/quebrada com um
/// placeholder (RF01) e expõe Semantics para leitor de tela (RF10).
class CharacterGridItem extends StatelessWidget {
  final Character character;
  final VoidCallback onTap;

  const CharacterGridItem({
    super.key,
    required this.character,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Personagem ${character.name}, espécie ${character.species}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Tamanho mínimo de toque confortável (RF10).
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: character.imageUrl.isEmpty
                    ? _Placeholder(name: character.name)
                    : Image.network(
                        character.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _Placeholder(name: character.name),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                child: Text(
                  character.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String name;
  const _Placeholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Semantics(
        label: 'Imagem indisponível para $name',
        child: const Icon(Icons.image_not_supported_outlined, size: 40),
      ),
    );
  }
}
