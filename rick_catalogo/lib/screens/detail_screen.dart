import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import '../providers/favorites_provider.dart';
import '../providers/consumed_provider.dart';
import '../widgets/error_view.dart';

class DetailScreen extends StatefulWidget {
  final int characterId;
  const DetailScreen({super.key, required this.characterId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _api = ApiService();
  late Future<Character> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchCharacterDetail(widget.characterId);
  }

  void _reload() {
    setState(() {
      _future = _api.fetchCharacterDetail(widget.characterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      // RF09 — FutureBuilder trata loading/erro/sucesso.
      body: FutureBuilder<Character>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Ocorreu um erro inesperado.';
            return ErrorView(message: message, onRetry: _reload);
          }

          final character = snapshot.data!;
          return _DetailBody(character: character);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Character character;
  const _DetailBody({required this.character});

  @override
  Widget build(BuildContext context) {
    return Consumer2<FavoritesProvider, ConsumedProvider>(
      builder: (context, favorites, consumed, _) {
        final isFav = favorites.isFavorite(character.id);
        final isDone = consumed.isConsumed(character.id);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Foto de ${character.name}',
                image: true,
                child: character.imageUrl.isEmpty
                    ? Container(
                        height: 280,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.image_not_supported_outlined, size: 64),
                      )
                    : Image.network(
                        character.imageUrl,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 280,
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          child: const Icon(Icons.image_not_supported_outlined, size: 64),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            character.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        // RF04 — favoritar/desfavoritar via Provider.
                        Semantics(
                          label: isFav
                              ? 'Remover ${character.name} dos favoritos'
                              : 'Adicionar ${character.name} aos favoritos',
                          button: true,
                          child: IconButton(
                            iconSize: 32,
                            icon: Icon(
                              isFav ? Icons.star : Icons.star_border,
                              color: isFav ? Colors.amber : null,
                            ),
                            onPressed: () => favorites.toggleFavorite(character),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Status', value: character.status),
                    _InfoRow(label: 'Espécie', value: character.species),
                    _InfoRow(label: 'Tipo', value: character.type),
                    _InfoRow(label: 'Gênero', value: character.gender),
                    _InfoRow(label: 'Origem', value: character.originName),
                    _InfoRow(label: 'Última localização', value: character.locationName),
                    const SizedBox(height: 20),
                    // RF07 — marcar como consumido/assistido.
                    OutlinedButton.icon(
                      onPressed: () => consumed.toggleConsumed(character),
                      icon: Icon(isDone ? Icons.check_circle : Icons.check_circle_outline),
                      label: Text(isDone ? 'Marcado como assistido' : 'Marcar como assistido'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$label: $value',
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}
