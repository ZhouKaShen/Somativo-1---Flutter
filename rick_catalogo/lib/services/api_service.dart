import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/character.dart';

/// Exceção amigável para exibir mensagens de erro na UI (RF09).
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Resultado de uma página de personagens: itens + se existe próxima página.
class CharacterPage {
  final List<Character> characters;
  final bool hasNext;
  CharacterPage(this.characters, this.hasNext);
}

class ApiService {
  static const _baseUrl = 'https://rickandmortyapi.com/api';

  /// RF01 — busca uma página de personagens.
  Future<CharacterPage> fetchCharacters({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl/character?page=$page');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 404) {
        // API retorna 404 quando a página não tem resultados (fim da lista).
        return CharacterPage([], false);
      }
      if (response.statusCode != 200) {
        throw ApiException(
            'Não foi possível carregar o catálogo agora (erro ${response.statusCode}).');
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final results = (body['results'] as List<dynamic>? ?? [])
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextPage = (body['info'] as Map<String, dynamic>?)?['next'];

      return CharacterPage(results, nextPage != null);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Sem conexão com a internet. Verifique sua rede e tente novamente.');
    }
  }

  /// RF03 — detalhe de um personagem específico.
  Future<Character> fetchCharacterDetail(int id) async {
    final uri = Uri.parse('$_baseUrl/character/$id');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw ApiException('Não foi possível carregar os detalhes deste item.');
      }
      return Character.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Sem conexão com a internet. Tente novamente.');
    }
  }

  /// RF08 — busca por nome. Retorna a lista de resultados (o chamador
  /// decide levar direto ao primeiro resultado, conforme pedido no RF08).
  Future<List<Character>> searchCharacters(String query) async {
    final uri = Uri.parse('$_baseUrl/character?name=${Uri.encodeQueryComponent(query)}');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) {
        return []; // nenhum resultado encontrado — não é erro de rede
      }
      if (response.statusCode != 200) {
        throw ApiException('Falha ao buscar "$query". Tente novamente.');
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return (body['results'] as List<dynamic>? ?? [])
          .map((e) => Character.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Sem conexão com a internet. Tente novamente.');
    }
  }
}
