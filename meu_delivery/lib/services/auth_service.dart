import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_storage.dart';

 
class AuthException implements Exception {
  final String mensagem;
  AuthException(this.mensagem);

  @override
  String toString() => mensagem;
}

class AuthService {
  AuthService._();

  static const _mensagemCredenciaisInvalidas = 'E-mail ou senha inválidos.';
  static const _mensagemErroConexao =
      'Não foi possível conectar ao servidor. Tente novamente.';

  
  static Future<void> login({
    required String email,
    required String senha,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.authLoginPath}');

    http.Response resposta;
    try {
      resposta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      throw AuthException(_mensagemErroConexao);
    }

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      final token = dados['token'] as String?;
      if (token == null || token.isEmpty) {
        throw AuthException('Servidor não retornou um token válido.');
      }
      await TokenStorage.salvarToken(token);
      return;
    }

   
    throw AuthException(_mensagemCredenciaisInvalidas);
  }


  static Future<void> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final uri =
        Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.authRegisterPath}');

    http.Response resposta;
    try {
      resposta = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nome': nome,
              'email': email,
              'telefone': telefone,
              'senha': senha,
            }),
          )
          .timeout(AppConfig.apiTimeout);
    } catch (_) {
      throw AuthException(_mensagemErroConexao);
    }

    if (resposta.statusCode == 200 || resposta.statusCode == 201) {
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      final token = dados['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await TokenStorage.salvarToken(token);
        return;
      }
      // API criou o cliente mas não mandou token junto -> loga em seguida.
      await login(email: email, senha: senha);
      return;
    }

    throw AuthException(
      'Não foi possível concluir o cadastro. Verifique os dados.',
    );
  }


  static Future<bool> tokenValido() async {
    final token = await TokenStorage.obterToken();
    if (token == null || token.isEmpty) return false;

    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.authMePath}');
      final resposta = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(AppConfig.apiTimeout);

      if (resposta.statusCode == 200) return true;

      if (resposta.statusCode == 401) {
        
        await TokenStorage.limparToken();
        return false;
      }

      return false;
    } catch (_) {
     
      return false;
    }
  }

  static Future<void> sair() async {
    await TokenStorage.limparToken();
  }
}
