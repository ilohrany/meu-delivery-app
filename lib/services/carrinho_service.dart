import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/carrinho.dart';
import 'token_storage.dart';

class CarrinhoException implements Exception {
  final String mensagem;
  final bool tokenInvalido;

  CarrinhoException(this.mensagem, {this.tokenInvalido = false});

  @override
  String toString() => mensagem;
}


class CarrinhoConflitoLojaException implements Exception {
  final String lojaAtualNome;

  CarrinhoConflitoLojaException(this.lojaAtualNome);
}

class CarrinhoService {
  CarrinhoService._();

  static Future<Map<String, String>> _cabecalhos() async {
    final token = await TokenStorage.obterToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Never _tratarErroConexao() {
    throw CarrinhoException(
      'Não foi possível conectar. Verifique sua conexão.',
    );
  }

  static Future<void> _tratarStatus(http.Response resposta) async {
    if (resposta.statusCode == 401) {
      await TokenStorage.limparToken();
      throw CarrinhoException('Sua sessão expirou.', tokenInvalido: true);
    }
  }

  static String _mensagemDoCorpo(http.Response resposta, String padrao) {
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map && corpo['error'] is String) {
        return corpo['error'] as String;
      }
    } catch (_) {}
    return padrao;
  }

  static Future<Carrinho> buscarCarrinho() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.carrinhoPath}');

    http.Response resposta;
    try {
      resposta = await http
          .get(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200) {
      throw CarrinhoException(
        _mensagemDoCorpo(resposta, 'Não foi possível carregar o carrinho.'),
      );
    }

    return Carrinho.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }


  static Future<Carrinho> adicionarItem({
    required String lojaId,
    required String produtoId,
    required int quantidade,
    required List<Map<String, String>> complementos,
    required String observacao,
    bool substituir = false,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.carrinhoItensPath}');

    http.Response resposta;
    try {
      resposta = await http
          .post(
            uri,
            headers: await _cabecalhos(),
            body: jsonEncode({
              'lojaId': lojaId,
              'produtoId': produtoId,
              'quantidade': quantidade,
              'complementos': complementos,
              'observacao': observacao,
              'substituir': substituir,
            }),
          )
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode == 409) {
      final corpo = jsonDecode(resposta.body);
      final lojaAtualNome = corpo is Map ? (corpo['lojaAtualNome'] as String? ?? 'outra loja') : 'outra loja';
      throw CarrinhoConflitoLojaException(lojaAtualNome);
    }

    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw CarrinhoException(
        _mensagemDoCorpo(resposta, 'Não foi possível adicionar ao carrinho.'),
      );
    }

    return Carrinho.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  static Future<Carrinho> atualizarItem({
    required String itemId,
    int? quantidade,
    List<Map<String, String>>? complementos,
    String? observacao,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.carrinhoItemPath(itemId)}',
    );

    http.Response resposta;
    try {
      resposta = await http
          .put(
            uri,
            headers: await _cabecalhos(),
            body: jsonEncode({
              if (quantidade != null) 'quantidade': quantidade,
              if (complementos != null) 'complementos': complementos,
              if (observacao != null) 'observacao': observacao,
            }),
          )
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200) {
      throw CarrinhoException(
        _mensagemDoCorpo(resposta, 'Não foi possível atualizar o item.'),
      );
    }

    return Carrinho.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  static Future<Carrinho> removerItem(String itemId) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.carrinhoItemPath(itemId)}',
    );

    http.Response resposta;
    try {
      resposta = await http
          .delete(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200) {
      throw CarrinhoException(
        _mensagemDoCorpo(resposta, 'Não foi possível remover o item.'),
      );
    }

    return Carrinho.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }
}
