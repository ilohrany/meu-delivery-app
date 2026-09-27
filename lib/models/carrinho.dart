import 'cardapio.dart';


class ComplementoEscolhido {
  final String grupoId;
  final String opcaoId;
  final String nome;
  final double preco;

  ComplementoEscolhido({
    required this.grupoId,
    required this.opcaoId,
    required this.nome,
    required this.preco,
  });

  factory ComplementoEscolhido.fromJson(Map<String, dynamic> json) {
    return ComplementoEscolhido(
      grupoId: json['grupoId'] ?? '',
      opcaoId: json['opcaoId'] ?? '',
      nome: json['nome'] ?? '',
      preco: (json['preco'] as num? ?? 0.0).toDouble(),
    );
  }
}

class ItemCarrinho {
  final String id;
  final Produto produto;
  final int quantidade;
  final String observacao;
  final List<ComplementoEscolhido> complementos;


  final double precoItem;

  ItemCarrinho({
    required this.id,
    required this.produto,
    required this.quantidade,
    required this.observacao,
    required this.complementos,
    required this.precoItem,
  });

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) {
    return ItemCarrinho(
      id: (json['id'] ?? '').toString(),
      produto: Produto.fromJson(json['produto'] as Map<String, dynamic>),
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 1,
      observacao: json['observacao'] as String? ?? '',
      complementos: (json['complementos'] as List? ?? [])
          .map((c) => ComplementoEscolhido.fromJson(c as Map<String, dynamic>))
          .toList(),
      precoItem: (json['precoItem'] as num? ?? 0.0).toDouble(),
    );
  }


  Map<String, List<String>> get selecoesPorGrupo {
    final mapa = <String, List<String>>{};
    for (final c in complementos) {
      mapa.putIfAbsent(c.grupoId, () => []).add(c.opcaoId);
    }
    return mapa;
  }
}

class Carrinho {
  final String? lojaId;
  final String? lojaNome;
  final List<ItemCarrinho> itens;


  final double subtotal;
  final double taxaEntrega;
  final double total;

  Carrinho({
    required this.lojaId,
    required this.lojaNome,
    required this.itens,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
  });

  factory Carrinho.fromJson(Map<String, dynamic> json) {
    return Carrinho(
      lojaId: json['lojaId'] as String?,
      lojaNome: json['lojaNome'] as String?,
      itens: (json['itens'] as List? ?? [])
          .map((i) => ItemCarrinho.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num? ?? 0.0).toDouble(),
      taxaEntrega: (json['taxaEntrega'] as num? ?? 0.0).toDouble(),
      total: (json['total'] as num? ?? 0.0).toDouble(),
    );
  }

  factory Carrinho.vazio() => Carrinho(
        lojaId: null,
        lojaNome: null,
        itens: const [],
        subtotal: 0,
        taxaEntrega: 0,
        total: 0,
      );

  bool get estaVazio => itens.isEmpty;

  int get quantidadeTotal =>
      itens.fold(0, (soma, item) => soma + item.quantidade);
}
