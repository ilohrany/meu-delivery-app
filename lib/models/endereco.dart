class Endereco {
  final String id;
  final String rua;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String pontoReferencia;
  final bool favorito;

  const Endereco({
    required this.id,
    required this.rua,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.pontoReferencia,
    required this.favorito,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: (json['id'] ?? '').toString(),
      rua: json['rua'] as String? ?? '',
      numero: json['numero'] as String? ?? '',
      complemento: json['complemento'] as String? ?? '',
      bairro: json['bairro'] as String? ?? '',
      cidade: json['cidade'] as String? ?? '',
      pontoReferencia: json['pontoReferencia'] as String? ?? '',
      favorito: json['favorito'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'pontoReferencia': pontoReferencia,
      'favorito': favorito,
    };
  }

  String get resumo {
    final partes = [
      '$rua, $numero',
      if (complemento.trim().isNotEmpty) complemento.trim(),
    ];
    return partes.join(' - ');
  }

  String get resumoBairroCidade {
    final partes = [
      if (bairro.trim().isNotEmpty) bairro.trim(),
      if (cidade.trim().isNotEmpty) cidade.trim(),
    ];
    return partes.join(' - ');
  }

  Endereco copyWith({
    String? rua,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? pontoReferencia,
    bool? favorito,
  }) {
    return Endereco(
      id: id,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      pontoReferencia: pontoReferencia ?? this.pontoReferencia,
      favorito: favorito ?? this.favorito,
    );
  }
}
