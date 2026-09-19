import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';

/* Centraliza toda a persistência local do app RF06 usando shared_preferences
cada "tabela" vira uma chave com uma lista/mapa serializado em JSON.*/

class StorageService {
  static const _kUsers = 'users'; // Map<username, password>
  static const _kLoggedUser = 'logged_user';
  static const _kFavoritesPrefix = 'favorites_'; // por usuário
  static const _kConsumedPrefix = 'consumed_'; // por usuário

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ---------------- Usuários / sessão (RF07 - login local) ----------------

  Future<Map<String, String>> _loadUsers(SharedPreferences prefs) async {
    final raw = prefs.getString(_kUsers);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  /// Cria um novo usuário local. Retorna false se o usuário já existe.
  Future<bool> registerUser(String username, String password) async {
    final prefs = await _prefs;
    final users = await _loadUsers(prefs);
    if (users.containsKey(username)) return false;
    users[username] = password;
    await prefs.setString(_kUsers, json.encode(users));
    return true;
  }

  /// Valida login local. Retorna true se usuário/senha batem.
  Future<bool> validateLogin(String username, String password) async {
    final prefs = await _prefs;
    final users = await _loadUsers(prefs);
    return users[username] == password;
  }

  Future<void> setLoggedUser(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_kLoggedUser, username);
  }

  Future<String?> getLoggedUser() async {
    final prefs = await _prefs;
    return prefs.getString(_kLoggedUser);
  }

  Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_kLoggedUser);
  }

  // ---------------- Favoritos (RF04/RF05/RF06) ----------------

  Future<List<Character>> loadFavorites(String username) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_kFavoritesPrefix$username');
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Character.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFavorites(String username, List<Character> favorites) async {
    final prefs = await _prefs;
    final encoded = json.encode(favorites.map((c) => c.toCacheJson()).toList());
    await prefs.setString('$_kFavoritesPrefix$username', encoded);
  }

  // ---------------- Itens consumidos (RF07/RF06) ----------------

  Future<List<Character>> loadConsumed(String username) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_kConsumedPrefix$username');
    if (raw == null) return [];
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Character.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConsumed(String username, List<Character> consumed) async {
    final prefs = await _prefs;
    final encoded = json.encode(consumed.map((c) => c.toCacheJson()).toList());
    await prefs.setString('$_kConsumedPrefix$username', encoded);
  }
}
