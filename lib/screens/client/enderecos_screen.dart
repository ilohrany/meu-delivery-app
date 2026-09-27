import 'package:flutter/material.dart';
import '../../models/endereco.dart';
import '../../services/endereco_service.dart';
import 'endereco_form_screen.dart';

class EnderecosScreen extends StatefulWidget {
  final VoidCallback? onSessaoExpirada;

  const EnderecosScreen({super.key, this.onSessaoExpirada});

  @override
  State<EnderecosScreen> createState() => _EnderecosScreenState();
}

class _EnderecosScreenState extends State<EnderecosScreen> {
  bool _carregando = true;
  String? _erro;
  List<Endereco> _enderecos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final enderecos = await EnderecoService.listarEnderecos();
      if (!mounted) return;
      setState(() {
        _enderecos = enderecos;
        _carregando = false;
      });
    } on EnderecoException catch (e) {
      if (!mounted) return;

      if (e.tokenInvalido) {
        widget.onSessaoExpirada?.call();
        return;
      }

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _novoEndereco() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EnderecoFormScreen()),
    );
    if (criado == true) _carregar();
  }

  Future<void> _editarEndereco(Endereco endereco) async {
    final editado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EnderecoFormScreen(enderecoExistente: endereco),
      ),
    );
    if (editado == true) _carregar();
  }

  Future<void> _marcarFavorito(Endereco endereco) async {
    if (endereco.favorito) return;

    final anterior = _enderecos;
   
    setState(() {
      _enderecos = _enderecos
          .map((e) => e.copyWith(favorito: e.id == endereco.id))
          .toList();
    });

    try {
      final atualizados = await EnderecoService.marcarFavorito(endereco.id);
      if (!mounted) return;
      setState(() => _enderecos = atualizados);
    } on EnderecoException catch (e) {
      if (!mounted) return;

      if (e.tokenInvalido) {
        widget.onSessaoExpirada?.call();
        return;
      }

      setState(() => _enderecos = anterior);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _confirmarRemocao(Endereco endereco) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover endereço'),
        content: Text('Deseja remover "${endereco.rua}, ${endereco.numero}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final anterior = _enderecos;
    setState(() => _enderecos = _enderecos.where((e) => e.id != endereco.id).toList());

    try {
      await EnderecoService.removerEndereco(endereco.id);
    } on EnderecoException catch (e) {
      if (!mounted) return;

      if (e.tokenInvalido) {
        widget.onSessaoExpirada?.call();
        return;
      }

      setState(() => _enderecos = anterior);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _corpo(),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoEndereco,
        tooltip: 'Novo endereço',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return _MensagemTela(
        icone: Icons.cloud_off,
        titulo: 'Não foi possível carregar',
        descricao: _erro!,
        textoBotao: 'Tentar novamente',
        aoClicar: _carregar,
      );
    }

    if (_enderecos.isEmpty) {
      return _MensagemTela(
        icone: Icons.location_off_outlined,
        titulo: 'Nenhum endereço cadastrado',
        descricao: 'Toque no + para adicionar seu primeiro endereço.',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: _enderecos.length,
        itemBuilder: (context, i) {
          final endereco = _enderecos[i];
          return _EnderecoCard(
            endereco: endereco,
            onEditar: () => _editarEndereco(endereco),
            onRemover: () => _confirmarRemocao(endereco),
            onFavoritar: () => _marcarFavorito(endereco),
          );
        },
      ),
    );
  }
}

class _EnderecoCard extends StatelessWidget {
  final Endereco endereco;
  final VoidCallback onEditar;
  final VoidCallback onRemover;
  final VoidCallback onFavoritar;

  const _EnderecoCard({
    required this.endereco,
    required this.onEditar,
    required this.onRemover,
    required this.onFavoritar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onEditar,
        leading: Icon(
          endereco.favorito ? Icons.star : Icons.location_on_outlined,
          color: endereco.favorito ? Colors.amber.shade700 : Colors.grey,
        ),
        title: Text(
          endereco.resumo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (endereco.resumoBairroCidade.isNotEmpty)
              Text(endereco.resumoBairroCidade),
            if (endereco.pontoReferencia.trim().isNotEmpty)
              Text(
                'Ref: ${endereco.pontoReferencia}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            if (endereco.favorito) ...[
              const SizedBox(height: 4),
              const Text(
                'Favorito',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (valor) {
            switch (valor) {
              case 'favoritar':
                onFavoritar();
                break;
              case 'editar':
                onEditar();
                break;
              case 'remover':
                onRemover();
                break;
            }
          },
          itemBuilder: (context) => [
            if (!endereco.favorito)
              const PopupMenuItem(
                value: 'favoritar',
                child: ListTile(
                  leading: Icon(Icons.star_outline),
                  title: Text('Marcar como favorito'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'remover',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Remover', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
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
