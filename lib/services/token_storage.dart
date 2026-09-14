import 'package:shared_preferences/shared_preferences.dart';

/// Guarda o token de autenticação no aparelho, para não precisar logar
/// de novo toda vez que o app é reaberto.
class TokenStorage {
  TokenStorage._();

  static const _chaveToken = 'quero_delivery_token';

  static Future<void> salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveToken, token);
  }

  static Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_chaveToken);
  }

  static Future<bool> temToken() async {
    final token = await obterToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> limparToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveToken);
  }
}
