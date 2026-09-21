
class Loja {
  final int id;
  final String nome;
  final String categoria;
  final String? fotoUrl;
  final int tempoEstimadoMin;
  final double taxaEntrega;
  final bool aberta;

  const Loja({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.fotoUrl,
    required this.tempoEstimadoMin,
    required this.taxaEntrega,
    required this.aberta,
  });

  factory Loja.fromJson(Map<String, dynamic> json) {
    return Loja(
      id: json['id'] as int,
      nome: json['nome'] as String? ?? 'Sem nome',
      categoria: json['categoria'] as String? ?? 'Outros',
      fotoUrl: json['fotoUrl'] as String?,
      tempoEstimadoMin: (json['tempoEstimadoMin'] as num?)?.toInt() ?? 0,
      taxaEntrega: (json['taxaEntrega'] as num?)?.toDouble() ?? 0,
    
      aberta: json['aberta'] as bool? ?? false,
    );
  }

  String get taxaFormatada {
    if (taxaEntrega <= 0) return 'Grátis';
    return 'R\$ ${taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
