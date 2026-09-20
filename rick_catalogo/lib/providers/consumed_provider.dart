import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ConsumedProvider extends ChangeNotifier {
  final StorageService _storage;
  final SupabaseClient _supabase = Supabase.instance.client;
  final ApiService _apiService = ApiService();
  String? _username;

  ConsumedProvider(this._storage);

  final List<Character> _consumed = [];
  List<Character> get consumed => List.unmodifiable(_consumed);

  bool isConsumed(int id) => _consumed.any((c) => c.id == id);

  /// Carrega dados priorizando a nuvem e fazendo fallback para o armazenamento local.
  Future<void> loadForUser(String username) async {
    _username = username;
    final userId = _supabase.auth.currentUser?.id;

    _consumed.clear();

    if (userId != null) {
      try {
        // 1. Tenta carregar do Supabase (Nuvem)
        final response = await _supabase
            .from('consumed')
            .select('character_id')
            .eq('user_id', userId);

        for (final item in (response as List)) {
          final charIdStr = item['character_id'].toString();
          final charId = int.tryParse(charIdStr);
          if (charId != null) {
            try {
              final character = await _apiService.fetchCharacterDetail(charId);
              _consumed.add(character);
            } catch (_) {}
          }
        }

        // Atualiza a cópia local com os dados da nuvem
        await _storage.saveConsumed(username, _consumed);
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Erro na nuvem, a carregar do cache local: $e');
      }
    }

    // 2. Fallback: Se estiver offline ou falhar a nuvem, lê a persistência local
    final localConsumed = await _storage.loadConsumed(username);
    _consumed.addAll(localConsumed);
    notifyListeners();
  }

  Future<void> toggleConsumed(Character character) async {
    final userId = _supabase.auth.currentUser?.id;
    final charIdStr = character.id.toString();

    if (isConsumed(character.id)) {
      _consumed.removeWhere((c) => c.id == character.id);
      notifyListeners();

      // Remove da Nuvem
      if (userId != null) {
        try {
          await _supabase
              .from('consumed')
              .delete()
              .eq('user_id', userId)
              .eq('character_id', charIdStr);
        } catch (_) {}
      }
    } else {
      _consumed.add(character);
      notifyListeners();

      // Salva na Nuvem
      if (userId != null) {
        try {
          await _supabase.from('consumed').insert({
            'user_id': userId,
            'character_id': charIdStr,
          });
        } catch (_) {}
      }
    }

    // Grava também na Persistência Local (RF06)
    if (_username != null) {
      await _storage.saveConsumed(_username!, _consumed);
    }
  }

  void clear() {
    _consumed.clear();
    _username = null;
    notifyListeners();
  }
}