class Categoria {
  final String id;
  final String nome;
  final List<Produto> produtos;

  Categoria({
    required this.id,
    required this.nome,
    required this.produtos,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      produtos: (json['produtos'] as List? ?? [])
          .map((p) => Produto.fromJson(p))
          .toList(),
    );
  }
}

class Produto {
  final String id;
  final String nome;
  final String descricao;
  final double precoBase;
  final String? fotoUrl;
  final bool disponivel;
  final List<GrupoComplemento> gruposComplemento;

  Produto({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.precoBase,
    this.fotoUrl,
    required this.disponivel,
    required this.gruposComplemento,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      precoBase: (json['precoBase'] as num? ?? 0.0).toDouble(),
      fotoUrl: json['fotoUrl'],
      disponivel: json['disponivel'] ?? true,
      gruposComplemento: (json['gruposComplemento'] as List? ?? [])
          .map((g) => GrupoComplemento.fromJson(g))
          .toList(),
    );
  }
}

class GrupoComplemento {
  final String id;
  final String titulo;
  final int minQtd;
  final int maxQtd;
  final List<OpcaoComplemento> opcoes;

  GrupoComplemento({
    required this.id,
    required this.titulo,
    required this.minQtd,
    required this.maxQtd,
    required this.opcoes,
  });

  factory GrupoComplemento.fromJson(Map<String, dynamic> json) {
    return GrupoComplemento(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      minQtd: json['minQtd'] ?? 0,
      maxQtd: json['maxQtd'] ?? 1,
      opcoes: (json['opcoes'] as List? ?? [])
          .map((o) => OpcaoComplemento.fromJson(o))
          .toList(),
    );
  }
}

class OpcaoComplemento {
  final String id;
  final String nome;
  final double preco;

  OpcaoComplemento({
    required this.id,
    required this.nome,
    required this.preco,
  });

  factory OpcaoComplemento.fromJson(Map<String, dynamic> json) {
    return OpcaoComplemento(
      id: json['id'] ?? '',
      nome: json['nome'] ?? '',
      preco: (json['preco'] as num? ?? 0.0).toDouble(),
    );
  }
}