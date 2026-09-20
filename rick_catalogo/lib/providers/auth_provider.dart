import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';

/// Gerencia o estado de sessão do usuário (RF07 - login local).
/// Fica disponível globalmente via Provider para controlar a navegação
/// condicional (logado -> Catálogo, deslogado -> Login).
class AuthProvider extends ChangeNotifier {
  final StorageService _storage;
  final SupabaseClient _supabase = Supabase.instance.client;
  

  AuthProvider(this._storage);

  
  bool _loading = true;

  String? get currentUser => _supabase.auth.currentUser?.email;
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  bool get loading => _loading;

  /// Chamado na inicialização do app para restaurar sessão salva.
  Future<void> restoreSession() async {
    _loading = false;
    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Preencha usuário e senha.';
    }

    try {
      _loading = true;
      notifyListeners();
      await _supabase.auth.signInWithPassword(
        email: username.trim(), password: password,);
        _loading = false;
        notifyListeners();
        return null; // sucesso (sem erro)
    } on AuthException catch (e) {
      _loading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return 'Erro ao realizar login. Tente novamente.';
    }
  }

  Future<String?> register(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Preencha usuário e senha.';
    }
    if (password.length < 6) {
      return 'A senha deve ter ao menos 6 caracteres.';
    }
    
    try {
      _loading = true;
      notifyListeners();
      await _supabase.auth.signUp(
        email: username.trim(),
        password: password,
      );
      _loading = false;
      notifyListeners();
      return null; // sucesso (sem erro)
    } on AuthException catch (e) {
      _loading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return 'Erro ao realizar cadastro. Tente novamente.';
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}
  