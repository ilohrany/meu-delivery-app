import 'package:flutter/material.dart';
import '../../models/cardapio.dart';
import '../../models/carrinho.dart';
import '../../services/carrinho_service.dart';

class ProdutoDetailModal extends StatefulWidget {
  final Produto produto;

  
  final String lojaId;

 
  final ItemCarrinho? itemExistente;

  const ProdutoDetailModal({
    super.key,
    required this.produto,
    required this.lojaId,
    this.itemExistente,
  });

  @override
  State<ProdutoDetailModal> createState() => _ProdutoDetailModalState();
}

class _ProdutoDetailModalState extends State<ProdutoDetailModal> {
  final Map<String, List<String>> _selecionadosIds = {};
  late final TextEditingController _observacaoController;
  int _quantidade = 1;
  bool _salvando = false;

  bool get _editando => widget.itemExistente != null;

  @override
  void initState() {
    super.initState();
    final selecoesIniciais = widget.itemExistente?.selecoesPorGrupo ?? const {};
    for (var grupo in widget.produto.gruposComplemento) {
      _selecionadosIds[grupo.id] = List.of(selecoesIniciais[grupo.id] ?? []);
    }
    _quantidade = widget.itemExistente?.quantidade ?? 1;
    _observacaoController =
        TextEditingController(text: widget.itemExistente?.observacao ?? '');
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
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
                content: Text('Máximo de ${grupo.maxQtd} opções neste grupo.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  List<Map<String, String>> get _complementosParaApi {
    final lista = <Map<String, String>>[];
    for (var grupo in widget.produto.gruposComplemento) {
      final ids = _selecionadosIds[grupo.id] ?? [];
      for (var opcao in grupo.opcoes) {
        if (ids.contains(opcao.id)) {
          lista.add({'grupoId': grupo.id, 'opcaoId': opcao.id});
        }
      }
    }
    return lista;
  }

  Future<void> _salvar({bool substituir = false}) async {
    setState(() => _salvando = true);

    try {
      if (_editando) {
        await CarrinhoService.atualizarItem(
          itemId: widget.itemExistente!.id,
          quantidade: _quantidade,
          complementos: _complementosParaApi,
          observacao: _observacaoController.text.trim(),
        );
      } else {
        await CarrinhoService.adicionarItem(
          lojaId: widget.lojaId,
          produtoId: widget.produto.id,
          quantidade: _quantidade,
          complementos: _complementosParaApi,
          observacao: _observacaoController.text.trim(),
          substituir: substituir,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on CarrinhoConflitoLojaException catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Trocar de loja?'),
          content: Text(
            'Seu carrinho já tem itens de "${e.lojaAtualNome}". '
            'Adicionar este produto vai esvaziar o carrinho atual. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Esvaziar e adicionar'),
            ),
          ],
        ),
      );
      if (confirmar == true) {
        await _salvar(substituir: true);
      }
    } on CarrinhoException catch (e) {
      if (!mounted) return;
      // Mantém o modal aberto com tudo que o cliente já escolheu.
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
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
              child: ListView(
                children: [
                  for (final grupo in widget.produto.gruposComplemento) ...[
                    _grupoWidget(grupo, disponivel),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacaoController,
                    enabled: disponivel,
                    maxLines: 2,
                    maxLength: 140,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                      hintText: 'Ex: sem cebola, ponto da carne, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _quantidade++),
                ),
                const Spacer(),
                Text(
                  'Total: R\$ ${_precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                onPressed: (disponivel && _validaLimites() && !_salvando)
                    ? () => _salvar()
                    : null,
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        !disponivel
                            ? 'Produto indisponível'
                            : _editando
                                ? 'Salvar alterações'
                                : 'Adicionar ao Carrinho',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grupoWidget(GrupoComplemento grupo, bool disponivel) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text(
                obrigatorio
                    ? 'Obrigatório · ${grupo.minQtd}–${grupo.maxQtd}'
                    : 'Opcional · até ${grupo.maxQtd}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        ...grupo.opcoes.map((opcao) {
          final selecionado = _selecionadosIds[grupo.id]?.contains(opcao.id) ?? false;
          return CheckboxListTile(
            enabled: disponivel,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(opcao.nome),
            subtitle: opcao.preco > 0
                ? Text('+ R\$ ${opcao.preco.toStringAsFixed(2).replaceAll('.', ',')}')
                : null,
            value: selecionado,
            onChanged: disponivel ? (_) => _toggleOpcao(grupo, opcao) : null,
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
