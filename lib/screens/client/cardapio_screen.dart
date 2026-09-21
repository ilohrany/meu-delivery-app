import 'package:flutter/material.dart';
import '../../models/loja.dart';
import '../../models/cardapio.dart';
import '../../services/loja_service.dart';
import 'produto_detail_modal.dart';

class CardapioScreen extends StatefulWidget {
  final Loja loja;

  const CardapioScreen({super.key, required this.loja});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
  List<Categoria> _categorias = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCardapio();
  }

  Future<void> _carregarCardapio() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final categorias = await LojaService.getCardapio(widget.loja.id);
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _carregando = false;
      });
    } on LojaException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar o cardápio.';
        _carregando = false;
      });
    }
  }

  void _abrirProduto(Produto produto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProdutoDetailModal(produto: produto),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.loja.nome),
        centerTitle: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar o cardápio',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _carregarCardapio,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Cardápio vazio',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta loja ainda não tem produtos cadastrados.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCardapio,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _categorias.length,
        itemBuilder: (context, index) {
          final categoria = _categorias[index];
          return _CategoriaSection(
            categoria: categoria,
            onProdutoTap: _abrirProduto,
          );
        },
      ),
    );
  }
}

class _CategoriaSection extends StatelessWidget {
  final Categoria categoria;
  final void Function(Produto) onProdutoTap;

  const _CategoriaSection({
    required this.categoria,
    required this.onProdutoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            categoria.nome,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...categoria.produtos.map(
          (produto) => _ProdutoTile(
            produto: produto,
            onTap: () => onProdutoTap(produto),
          ),
        ),
      ],
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  final Produto produto;
  final VoidCallback onTap;

  const _ProdutoTile({
    required this.produto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disponivel = produto.disponivel;

    return Opacity(
      opacity: disponivel ? 1.0 : 0.55,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FotoProduto(fotoUrl: produto.fotoUrl, disponivel: disponivel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            produto.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              decoration: disponivel
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (!disponivel)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              'Indisponível',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (produto.descricao.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        produto.descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'R\$ ${produto.precoBase.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: disponivel
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoProduto extends StatelessWidget {
  final String? fotoUrl;
  final bool disponivel;

  const _FotoProduto({this.fotoUrl, required this.disponivel});

  @override
  Widget build(BuildContext context) {
    const tamanho = 72.0;

    Widget imagem;
    if (fotoUrl == null || fotoUrl!.isEmpty) {
      imagem = _placeholder(tamanho);
    } else {
      imagem = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fotoUrl!,
          width: tamanho,
          height: tamanho,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(tamanho),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: tamanho,
              height: tamanho,
              color: Colors.grey.shade200,
              child: const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return imagem;
  }

  Widget _placeholder(double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fastfood, color: Colors.grey.shade500),
    );
  }
}