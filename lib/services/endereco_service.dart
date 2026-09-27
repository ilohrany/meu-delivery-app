import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/endereco.dart';
import 'token_storage.dart';

class EnderecoException implements Exception {
  final String mensagem;
  final bool tokenInvalido;

  EnderecoException(this.mensagem, {this.tokenInvalido = false});

  @override
  String toString() => mensagem;
}

class EnderecoService {
  EnderecoService._();

  static Future<Map<String, String>> _cabecalhos() async {
    final token = await TokenStorage.obterToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Never _tratarErroConexao() {
    throw EnderecoException(
      'Não foi possível conectar. Verifique sua conexão.',
    );
  }

  static Future<void> _tratarStatus(http.Response resposta) async {
    if (resposta.statusCode == 401) {
      await TokenStorage.limparToken();
      throw EnderecoException('Sua sessão expirou.', tokenInvalido: true);
    }
  }

  static String _mensagemDoCorpo(http.Response resposta, String padrao) {
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map && corpo['error'] is String) {
        return corpo['error'] as String;
      }
    } catch (_) {
     
    }
    return padrao;
  }

  static Future<List<Endereco>> listarEnderecos() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.enderecosPath}');

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
      throw EnderecoException(
        _mensagemDoCorpo(resposta, 'Não foi possível carregar os endereços.'),
      );
    }

    final corpo = jsonDecode(resposta.body);
    final lista =
        corpo is List ? corpo : (corpo['enderecos'] as List? ?? []);
    return lista
        .map((e) => Endereco.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Endereco> criarEndereco(Endereco endereco) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.enderecosPath}');

    http.Response resposta;
    try {
      resposta = await http
          .post(uri, headers: await _cabecalhos(), body: jsonEncode(endereco.toJson()))
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200 && resposta.statusCode != 201) {
      throw EnderecoException(
        _mensagemDoCorpo(resposta, 'Não foi possível salvar o endereço.'),
      );
    }

    return Endereco.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  static Future<Endereco> atualizarEndereco(Endereco endereco) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.enderecoPath(endereco.id)}',
    );

    http.Response resposta;
    try {
      resposta = await http
          .put(uri, headers: await _cabecalhos(), body: jsonEncode(endereco.toJson()))
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200) {
      throw EnderecoException(
        _mensagemDoCorpo(resposta, 'Não foi possível salvar o endereço.'),
      );
    }

    return Endereco.fromJson(jsonDecode(resposta.body) as Map<String, dynamic>);
  }

  static Future<void> removerEndereco(String id) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.enderecoPath(id)}');

    http.Response resposta;
    try {
      resposta = await http
          .delete(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200 && resposta.statusCode != 204) {
      throw EnderecoException(
        _mensagemDoCorpo(resposta, 'Não foi possível remover o endereço.'),
      );
    }
  }

  static Future<List<Endereco>> marcarFavorito(String id) async {
    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${AppConfig.enderecoFavoritoPath(id)}',
    );

    http.Response resposta;
    try {
      resposta = await http
          .post(uri, headers: await _cabecalhos())
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      _tratarErroConexao();
    }

    await _tratarStatus(resposta);

    if (resposta.statusCode != 200) {
      throw EnderecoException(
        _mensagemDoCorpo(resposta, 'Não foi possível marcar como favorito.'),
      );
    }

    final corpo = jsonDecode(resposta.body);
    final lista =
        corpo is List ? corpo : (corpo['enderecos'] as List? ?? []);
    return lista
        .map((e) => Endereco.fromJson(e as Map<String, dynamic>))
        .toList();
  }


  static Future<Endereco?> buscarFavorito() async {
    final lista = await listarEnderecos();
    if (lista.isEmpty) return null;
    for (final endereco in lista) {
      if (endereco.favorito) return endereco;
    }
    return lista.first;
  }
}