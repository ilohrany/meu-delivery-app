import 'package:flutter/material.dart';
import '../../models/endereco.dart';
import '../../services/endereco_service.dart';

class EnderecoFormScreen extends StatefulWidget {
  final Endereco? enderecoExistente;

  const EnderecoFormScreen({super.key, this.enderecoExistente});

  @override
  State<EnderecoFormScreen> createState() => _EnderecoFormScreenState();
}

class _EnderecoFormScreenState extends State<EnderecoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _ruaController;
  late final TextEditingController _numeroController;
  late final TextEditingController _complementoController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cidadeController;
  late final TextEditingController _referenciaController;
  late bool _favorito;

  bool _salvando = false;
  String? _erroSalvar;

  bool get _editando => widget.enderecoExistente != null;

  @override
  void initState() {
    super.initState();
    final e = widget.enderecoExistente;
    _ruaController = TextEditingController(text: e?.rua ?? '');
    _numeroController = TextEditingController(text: e?.numero ?? '');
    _complementoController = TextEditingController(text: e?.complemento ?? '');
    _bairroController = TextEditingController(text: e?.bairro ?? '');
    _cidadeController = TextEditingController(text: e?.cidade ?? '');
    _referenciaController = TextEditingController(text: e?.pontoReferencia ?? '');
    _favorito = e?.favorito ?? false;
  }

  @override
  void dispose() {
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
      _erroSalvar = null;
    });

    final endereco = Endereco(
      id: widget.enderecoExistente?.id ?? '',
      rua: _ruaController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      pontoReferencia: _referenciaController.text.trim(),
      favorito: _favorito,
    );

    try {
      if (_editando) {
        await EnderecoService.atualizarEndereco(endereco);
      } else {
        await EnderecoService.criarEndereco(endereco);
      }
      if (!mounted) return;
      
      Navigator.of(context).pop(true);
    } on EnderecoException catch (e) {
      if (!mounted) return;
     
      setState(() {
        _salvando = false;
        _erroSalvar = e.mensagem;
      });
    }
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar endereço' : 'Novo endereço'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_erroSalvar != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erroSalvar!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TextFormField(
              controller: _ruaController,
              decoration: const InputDecoration(labelText: 'Rua'),
              validator: _obrigatorio,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                    validator: _obrigatorio,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _complementoController,
                    decoration: const InputDecoration(
                      labelText: 'Complemento (opcional)',
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro'),
              validator: _obrigatorio,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade'),
              validator: _obrigatorio,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenciaController,
              decoration: const InputDecoration(
                labelText: 'Ponto de referência (opcional)',
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Marcar como favorito'),
              subtitle: const Text(
                'Vem selecionado por padrão na hora do pedido',
              ),
              value: _favorito,
              onChanged: (v) => setState(() => _favorito = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editando ? 'Salvar alterações' : 'Adicionar endereço'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
