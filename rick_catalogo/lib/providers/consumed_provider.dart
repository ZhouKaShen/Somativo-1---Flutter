import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../services/storage_service.dart';

/// Estado global dos itens marcados como "consumidos" (RF07).
class ConsumedProvider extends ChangeNotifier {
  final StorageService _storage;
  String? _username;

  ConsumedProvider(this._storage);

  final List<Character> _consumed = [];
  List<Character> get consumed => List.unmodifiable(_consumed);

  bool isConsumed(int id) => _consumed.any((c) => c.id == id);

  Future<void> loadForUser(String username) async {
    _username = username;
    _consumed
      ..clear()
      ..addAll(await _storage.loadConsumed(username));
    notifyListeners();
  }

  Future<void> toggleConsumed(Character character) async {
    if (isConsumed(character.id)) {
      _consumed.removeWhere((c) => c.id == character.id);
    } else {
      _consumed.add(character);
    }
    notifyListeners();
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
