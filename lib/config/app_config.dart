class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String healthCheckPath = '/health';

  // Autenticação
  static const String authLoginPath = '/auth/login';
  static const String authRegisterPath = '/auth/cadastro';
  static const String authMePath = '/auth/me';

  // Lojas e Categorias
  static const String lojasPath = '/lojas';
  static const String categoriasPath = '/categorias';
  static String cardapioPath(dynamic lojaId) => '/lojas/$lojaId/cardapio';

  // Endereços
  static const String enderecosPath = '/enderecos';
  static String enderecoPath(dynamic id) => '/enderecos/$id';
  static String enderecoFavoritoPath(dynamic id) => '/enderecos/$id/favorito';

  // Carrinho
  static const String carrinhoPath = '/carrinho';
  static const String carrinhoItensPath = '/carrinho/itens';
  static String carrinhoItemPath(dynamic itemId) => '/carrinho/itens/$itemId';

  static const Duration apiTimeout = Duration(seconds: 5);
}