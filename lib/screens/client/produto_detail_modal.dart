import 'package:flutter/material.dart';
import '../../models/cardapio.dart';

class ProdutoDetailModal extends StatefulWidget {
  final Produto produto;

  const ProdutoDetailModal({super.key, required this.produto});

  @override
  State<ProdutoDetailModal> createState() => _ProdutoDetailModalState();
}

class _ProdutoDetailModalState extends State<ProdutoDetailModal> {
  
  final Map<String, List<String>> _selecionadosIds = {};
  int _quantidade = 1;

  @override
  void initState() {
    super.initState();
    for (var grupo in widget.produto.gruposComplemento) {
      _selecionadosIds[grupo.id] = [];
    }
  }

  double get _precoTotal {
    double totalComplementos = 0.0;
    for (var grupo in widget.produto.gruposComplemento) {
      final ids = _selecionadosIds[grupo.id] ?? [];
      for (var opcao in grupo.opcoes) {
        if (ids.contains(opcao.id)) {
          totalComplementos += opcao.preco;
        }
      }
    }
    return (widget.produto.precoBase + totalComplementos) * _quantidade;
  }

  bool _validaLimites() {
    for (var grupo in widget.produto.gruposComplemento) {
      final qtdSelecionada = _selecionadosIds[grupo.id]?.length ?? 0;
      if (qtdSelecionada < grupo.minQtd) {
        return false;
      }
    }
    return true;
  }

  void _toggleOpcao(GrupoComplemento grupo, OpcaoComplemento opcao) {
    setState(() {
      final lista = _selecionadosIds[grupo.id]!;
      if (grupo.maxQtd == 1) {
        
        lista.clear();
        lista.add(opcao.id);
      } else {
        if (lista.contains(opcao.id)) {
          lista.remove(opcao.id);
        } else {
          if (lista.length < grupo.maxQtd) {
            lista.add(opcao.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Máximo de ${grupo.maxQtd} opções neste grupo.',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool disponivel = widget.produto.disponivel;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.produto.nome,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (!disponivel)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PRODUTO INDISPONÍVEL',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.produto.descricao.isNotEmpty)
              Text(
                widget.produto.descricao,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: widget.produto.gruposComplemento.length,
                itemBuilder: (context, index) {
                  final grupo = widget.produto.gruposComplemento[index];
                  final obrigatorio = grupo.minQtd > 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                grupo.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              obrigatorio
                                  ? 'Obrigatório · ${grupo.minQtd}–${grupo.maxQtd}'
                                  : 'Opcional · até ${grupo.maxQtd}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...grupo.opcoes.map((opcao) {
                        final selecionado =
                            _selecionadosIds[grupo.id]?.contains(opcao.id) ??
                                false;
                        return CheckboxListTile(
                          enabled: disponivel,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(opcao.nome),
                          subtitle: opcao.preco > 0
                              ? Text(
                                  '+ R\$ ${opcao.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                                )
                              : null,
                          value: selecionado,
                          onChanged: disponivel
                              ? (_) => _toggleOpcao(grupo, opcao)
                              : null,
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
           
            Row(
              children: [
                const Text('Qtd:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantidade > 1
                      ? () => setState(() => _quantidade--)
                      : null,
                ),
                Text(
                  '$_quantidade',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantidade++),
                ),
                const Spacer(),
                Text(
                  'Total: R\$ ${_precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: (disponivel && _validaLimites())
                    ? () {
                        // Por enquanto só fecha (carrinho é próxima tarefa)
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.produto.nome} adicionado (simulação)',
                            ),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  disponivel
                      ? 'Adicionar ao Carrinho'
                      : 'Produto indisponível',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}