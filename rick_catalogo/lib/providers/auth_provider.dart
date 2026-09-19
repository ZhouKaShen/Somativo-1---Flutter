import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Gerencia o estado de sessão do usuário (RF07 - login local).
/// Fica disponível globalmente via Provider para controlar a navegação
/// condicional (logado -> Catálogo, deslogado -> Login).
class AuthProvider extends ChangeNotifier {
  final StorageService _storage;

  AuthProvider(this._storage);

  String? _currentUser;
  bool _loading = true;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;

  /// Chamado na inicialização do app para restaurar sessão salva.
  Future<void> restoreSession() async {
    _currentUser = await _storage.getLoggedUser();
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Preencha usuário e senha.';
    }
    final valid = await _storage.validateLogin(username.trim(), password);
    if (!valid) {
      return 'Usuário ou senha inválidos.';
    }
    _currentUser = username.trim();
    await _storage.setLoggedUser(_currentUser!);
    notifyListeners();
    return null; // sem erro
  }

  Future<String?> register(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Preencha usuário e senha.';
    }
    if (password.length < 4) {
      return 'A senha deve ter ao menos 4 caracteres.';
    }
    final created = await _storage.registerUser(username.trim(), password);
    if (!created) {
      return 'Esse usuário já existe.';
    }
    _currentUser = username.trim();
    await _storage.setLoggedUser(_currentUser!);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    await _storage.logout();
    _currentUser = null;
    notifyListeners();
  }
}
