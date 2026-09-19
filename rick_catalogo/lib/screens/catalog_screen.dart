import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/consumed_provider.dart';
import '../widgets/character_grid_item.dart';
import '../widgets/error_view.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'consumed_screen.dart';
import 'login_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();

  final List<Character> _characters = [];
  int _page = 1;
  bool _hasNext = true;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
    });
    try {
      final result = await _api.fetchCharacters(page: 1);
      setState(() {
        _characters
          ..clear()
          ..addAll(result.characters);
        _page = 1;
        _hasNext = result.hasNext;
        _loadingInitial = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loadingInitial = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _api.fetchCharacters(page: _page + 1);
      setState(() {
        _characters.addAll(result.characters);
        _page += 1;
        _hasNext = result.hasNext;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      setState(() => _loadingMore = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);
    try {
      final results = await _api.searchCharacters(query);
      if (!mounted) return;
      setState(() => _searching = false);

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nenhum personagem encontrado para "$query".')),
        );
        return;
      }

      // RF08 — busca leva direto para a tela de detalhes do resultado.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailScreen(characterId: results.first.id)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _logout() async {
    context.read<FavoritesProvider>().clear();
    context.read<ConsumedProvider>().clear();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Favoritos',
            icon: const Icon(Icons.favorite),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Consumidos',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConsumedScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Campo de busca por nome do personagem',
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar personagem...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _searching
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton.filled(
                        tooltip: 'Buscar',
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                      ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadInitial);
    }
    if (_characters.isEmpty) {
      return const Center(child: Text('Nenhum personagem carregado.'));
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final character = _characters[index];
                  return CharacterGridItem(
                    character: character,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(characterId: character.id),
                      ),
                    ),
                  );
                },
                childCount: _characters.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: !_hasNext
                    ? const Text('Fim da lista.')
                    : _loadingMore
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _loadMore,
                            child: const Text('Carregar Mais'),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
