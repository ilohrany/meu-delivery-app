import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/loja.dart';
import 'token_storage.dart';
import '../models/cardapio.dart';


class LojaException implements Exception {
  final String mensagem;

 
  final bool tokenInvalido;

  LojaException(this.mensagem, {this.tokenInvalido = false});

  @override
  String toString() => mensagem;
}

class LojaService {
  LojaService._();

  
  static Future<Map<String, String>> _cabecalhos() async {
    final token = await TokenStorage.obterToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }


  static Future<List<Loja>> listarLojas({
    String? busca,
    String? categoria,
  }) async {
    final params = <String, String>{};
    if (busca != null && busca.trim().isNotEmpty) {
      params['busca'] = busca.trim();
    }
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }

    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.lojasPath}')
        .replace(queryParameters: params.isEmpty ? null : params);

    http.Response resposta;
    try {
      resposta = await http
          .get(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      throw LojaException(
        'Não foi possível carregar as lojas. Verifique sua conexão.',
      );
    }

    if (resposta.statusCode == 401) {
      await TokenStorage.limparToken();
      throw LojaException('Sua sessão expirou.', tokenInvalido: true);
    }

    if (resposta.statusCode != 200) {
      throw LojaException('Não foi possível carregar as lojas.');
    }

    final corpo = jsonDecode(resposta.body);
    final lista = corpo is List ? corpo : (corpo['lojas'] as List? ?? []);
    return lista
        .map((e) => Loja.fromJson(e as Map<String, dynamic>))
        .toList();
  }

 
  static Future<List<String>> listarCategorias() async {
    try {
      final uri =
          Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.categoriasPath}');
      final resposta = await http
          .get(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);

      if (resposta.statusCode != 200) return [];

      final corpo = jsonDecode(resposta.body);
      final lista =
          corpo is List ? corpo : (corpo['categorias'] as List? ?? []);
      return lista.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
 
  static Future<List<Categoria>> getCardapio(String lojaId) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.cardapioPath(lojaId)}',
    );

    http.Response resposta;
    try {
      resposta = await http
          .get(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      throw LojaException(
        'Não foi possível carregar o cardápio. Verifique sua conexão.',
      );
    }

    if (resposta.statusCode == 401) {
      await TokenStorage.limparToken();
      throw LojaException('Sua sessão expirou.', tokenInvalido: true);
    }

    if (resposta.statusCode == 404) {
      throw LojaException('Cardápio não encontrado para esta loja.');
    }

    if (resposta.statusCode != 200) {
      throw LojaException('Não foi possível carregar o cardápio.');
    }

    final corpo = jsonDecode(resposta.body);
    final lista = corpo is List ? corpo : (corpo['categorias'] as List? ?? []);
    return lista
        .map((e) => Categoria.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}