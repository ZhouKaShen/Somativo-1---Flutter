import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../services/storage_service.dart';

/// Estado global dos favoritos (RF04). Qualquer tela que consome este
/// provider (Detalhes, Lista de Favoritos) reage automaticamente às
/// mudanças, sem precisar de callbacks manuais entre telas.
class FavoritesProvider extends ChangeNotifier {
  final StorageService _storage;
  String? _username;

  FavoritesProvider(this._storage);

  final List<Character> _favorites = [];
  List<Character> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int id) => _favorites.any((c) => c.id == id);

  /// Carrega os favoritos do usuário logado. Deve ser chamado após login.
  Future<void> loadForUser(String username) async {
    _username = username;
    _favorites
      ..clear()
      ..addAll(await _storage.loadFavorites(username));
    notifyListeners();
  }

  Future<void> toggleFavorite(Character character) async {
    if (isFavorite(character.id)) {
      _favorites.removeWhere((c) => c.id == character.id);
    } else {
      _favorites.add(character);
    }
    notifyListeners();
    if (_username != null) {
      await _storage.saveFavorites(_username!, _favorites);
    }
  }

  /// Limpa o estado em memória (chamado no logout, para não vazar
  /// dados de um usuário para o próximo que logar no mesmo aparelho).
  void clear() {
    _favorites.clear();
    _username = null;
    notifyListeners();
  }
}
