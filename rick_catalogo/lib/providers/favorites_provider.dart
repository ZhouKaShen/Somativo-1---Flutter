import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final StorageService _storage;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();
  String? _username;

  FavoritesProvider(this._storage);

  final List<Character> _favorites = [];
  List<Character> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(int id) => _favorites.any((c) => c.id == id);

  /// Carrega dados priorizando a nuvem e fazendo fallback para o armazenamento local.
  Future<void> loadForUser(String username) async {
    _username = username;
    final userId = _supabase.auth.currentUser?.id;

    _favorites.clear();

    if (userId != null) {
      try {
        // 1. Tenta carregar do Supabase (Nuvem)
        final response = await _supabase
            .from('favorites')
            .select('character_id')
            .eq('user_id', userId);

        for (final item in (response as List)) {
          final charIdStr = item['character_id'].toString();
          final charId = int.tryParse(charIdStr);
          if (charId != null) {
            try {
              final character = await _apiService.fetchCharacterDetail(charId);
              _favorites.add(character);
            } catch (_) {}
          }
        }

        // Atualiza a cópia local com os dados da nuvem
        await _storage.saveFavorites(username, _favorites);
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Erro na nuvem, a carregar do cache local: $e');
      }
    }

    // 2. Fallback: Se estiver offline ou falhar a nuvem, lê a persistência local
    final localFavorites = await _storage.loadFavorites(username);
    _favorites.addAll(localFavorites);
    notifyListeners();
  }

  Future<void> toggleFavorite(Character character) async {
    final userId = _supabase.auth.currentUser?.id;
    final charIdStr = character.id.toString();

    if (isFavorite(character.id)) {
      _favorites.removeWhere((c) => c.id == character.id);
      notifyListeners();

      // Remove da Nuvem
      if (userId != null) {
        try {
          await _supabase
              .from('favorites')
              .delete()
              .eq('user_id', userId)
              .eq('character_id', charIdStr);
        } catch (_) {}
      }
    } else {
      _favorites.add(character);
      notifyListeners();

      // Salva na Nuvem
      if (userId != null) {
        try {
          await _supabase.from('favorites').insert({
            'user_id': userId,
            'character_id': charIdStr,
          });
        } catch (_) {}
      }
    }

    // Grava também na Persistência Local (RF06)
    if (_username != null) {
      await _storage.saveFavorites(_username!, _favorites);
    }
  }

  void clear() {
    _favorites.clear();
    _username = null;
    notifyListeners();
  }
}