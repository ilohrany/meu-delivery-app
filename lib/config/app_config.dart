
class AppConfig {
  AppConfig._(); 


  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

 
  static const String healthCheckPath = '/health';


  static const String authLoginPath = '/auth/login';
  static const String authRegisterPath = '/auth/cadastro';
  static const String authMePath = '/auth/me';

  static String cardapioPath(String lojaId) => '/lojas/$lojaId/cardapio';
  static const String lojasPath = '/lojas';
  static const String categoriasPath = '/categorias';

  static const Duration apiTimeout = Duration(seconds: 5);
}
