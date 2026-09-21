import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/loja.dart';
import '../../services/loja_service.dart';
import '../../widgets/loja_card.dart';


class LojasScreen extends StatefulWidget {

  final VoidCallback? onSessaoExpirada;

  const LojasScreen({super.key, this.onSessaoExpirada});

  @override
  State<LojasScreen> createState() => _LojasScreenState();
}

class _LojasScreenState extends State<LojasScreen> {
  final _buscaController = TextEditingController();
  Timer? _debounce;

  List<Loja> _lojas = [];
  List<String> _categorias = [];
  String? _categoriaSelecionada;

  bool _carregando = true;
  String? _erroRede;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    await Future.wait([_carregarCategorias(), _carregarLojas()]);
  }

  Future<void> _carregarCategorias() async {
    final categorias = await LojaService.listarCategorias();
    if (!mounted) return;
    setState(() => _categorias = categorias);
  }

  Future<void> _carregarLojas() async {
    setState(() {
      _carregando = true;
      _erroRede = null;
    });

    try {
      final lojas = await LojaService.listarLojas(
        busca: _buscaController.text,
        categoria: _categoriaSelecionada,
      );
      if (!mounted) return;
      setState(() {
        _lojas = lojas;
        _carregando = false;
      });
    } on LojaException catch (e) {
      if (!mounted) return;

      if (e.tokenInvalido) {
        
        widget.onSessaoExpirada?.call();
        return;
      }

      setState(() {
        _erroRede = e.mensagem;
        _carregando = false;
      });
    }
  }

  
  void _aoDigitarBusca(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _carregarLojas);
  }

  void _selecionarCategoria(String? categoria) {
    setState(() => _categoriaSelecionada = categoria);
    _carregarLojas();
  }

  void _limparFiltros() {
    _buscaController.clear();
    setState(() => _categoriaSelecionada = null);
    _carregarLojas();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _barraBusca(),
        if (_categorias.isNotEmpty) _filtroCategorias(),
        Expanded(child: _conteudo()),
      ],
    );
  }

  Widget _barraBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _buscaController,
        onChanged: _aoDigitarBusca,
        decoration: InputDecoration(
          hintText: 'Buscar loja pelo nome...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _buscaController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscaController.clear();
                    _carregarLojas();
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _filtroCategorias() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: _categoriaSelecionada == null,
              onSelected: (_) => _selecionarCategoria(null),
            ),
          ),
          ..._categorias.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: ChoiceChip(
                label: Text(c),
                selected: _categoriaSelecionada == c,
                onSelected: (selecionado) =>
                    _selecionarCategoria(selecionado ? c : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    
    if (_erroRede != null) {
      return _MensagemTela(
        icone: Icons.cloud_off,
        titulo: 'Não foi possível carregar',
        descricao: _erroRede!,
        textoBotao: 'Tentar novamente',
        aoClicar: _carregarLojas,
      );
    }

    
    if (_lojas.isEmpty) {
      final comFiltro = _buscaController.text.isNotEmpty ||
          _categoriaSelecionada != null;
      return _MensagemTela(
        icone: Icons.storefront_outlined,
        titulo: comFiltro
            ? 'Nenhuma loja encontrada'
            : 'Nenhuma loja disponível',
        descricao: comFiltro
            ? 'Tente outro nome ou outra categoria.'
            : 'Ainda não há lojas cadastradas por aqui.',
        textoBotao: comFiltro ? 'Limpar filtros' : null,
        aoClicar: comFiltro ? _limparFiltros : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarLojas,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: _lojas.length,
        itemBuilder: (context, i) {
          final loja = _lojas[i];
          return LojaCard(
            loja: loja,
            onTap: () {
             
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Abrir ${loja.nome} (próxima tarefa)')),
              );
            },
          );
        },
      ),
    );
  }
}


class _MensagemTela extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final String? textoBotao;
  final VoidCallback? aoClicar;

  const _MensagemTela({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.textoBotao,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (textoBotao != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: aoClicar,
                icon: const Icon(Icons.refresh),
                label: Text(textoBotao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
