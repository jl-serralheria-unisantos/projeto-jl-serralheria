import 'dart:async';

import 'package:flutter/material.dart';

typedef _Registro = ({String tipo, String? id});

// Mantém o bloqueio enquanto o Future do SDK estiver pendente, mesmo que o
// diálogo ou a página da lista sejam fechados. O escopo é a sessão do app.
final _gravacoes = Expando<Set<_Registro>>();

Future<void> abrirDialogoCadastro({
  required BuildContext context,
  required Object sessao,
  required String tipo,
  required String? id,
  required String titulo,
  required Widget conteudo,
  required Future<void> Function() gravar,
}) async {
  final registro = (tipo: tipo, id: id);
  final pendentes = _gravacoes[sessao] ??= {};
  if (pendentes.contains(registro)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ainda existe uma gravação pendente. Aguarde a confirmação antes de tentar novamente.',
        ),
      ),
    );
    return;
  }
  final navigator = Navigator.of(context, rootNavigator: true);
  final rota = DialogRoute<void>(
    context: context,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierDismissible: false,
    builder: (_) => _DialogoCadastro(
      tipo: tipo,
      titulo: titulo,
      conteudo: conteudo,
      iniciar: () => pendentes.add(registro),
      finalizar: () => pendentes.remove(registro),
      gravar: gravar,
    ),
  );
  unawaited(navigator.push(rota));
  // completed também cobre o descarte do Navigator com a rota ainda aberta.
  await rota.completed;
}

class _DialogoCadastro extends StatefulWidget {
  const _DialogoCadastro({
    required this.tipo,
    required this.titulo,
    required this.conteudo,
    required this.iniciar,
    required this.finalizar,
    required this.gravar,
  });

  final String tipo;
  final String titulo;
  final Widget conteudo;
  final bool Function() iniciar;
  final VoidCallback finalizar;
  final Future<void> Function() gravar;

  @override
  State<_DialogoCadastro> createState() => _DialogoCadastroState();
}

class _DialogoCadastroState extends State<_DialogoCadastro> {
  final _form = GlobalKey<FormState>();
  bool _salvando = false;
  bool _aguardando = false;
  Timer? _tempoDeEspera;

  bool get _ativo => mounted && ModalRoute.of(context)?.isCurrent == true;

  @override
  void dispose() {
    _tempoDeEspera?.cancel();
    super.dispose();
  }

  void _cancelar() {
    if (_ativo && !_salvando) Navigator.pop(context);
  }

  void _sairEAguardar() {
    if (_ativo && _salvando && _aguardando) Navigator.pop(context);
  }

  Future<void> _salvar() async {
    if (!_ativo || _salvando || !_form.currentState!.validate()) return;
    if (!widget.iniciar()) return;
    setState(() => _salvando = true);
    FocusScope.of(context).unfocus();
    final rota = ModalRoute.of(context)!;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final tipo = widget.tipo;
    final finalizar = widget.finalizar;
    _tempoDeEspera = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _aguardando = true);
    });
    try {
      await widget.gravar();
      if (mounted && rota.isCurrent && navigator.mounted) {
        navigator.pop();
      } else if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gravação de $tipo concluída.')),
        );
      }
    } catch (erro) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _aguardando = false;
        });
      }
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erro ao salvar $tipo: $erro')),
        );
      }
    } finally {
      _tempoDeEspera?.cancel();
      finalizar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (fechou, _) {
        if (!fechou) _cancelar();
      },
      child: AlertDialog(
        title: Text(widget.titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_aguardando)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'A gravação ainda está pendente. Se sair, ela poderá concluir depois. '
                  'Aguarde a confirmação antes de tentar novamente.',
                ),
              ),
            Flexible(
              child: ExcludeFocus(
                excluding: _salvando,
                child: IgnorePointer(
                  ignoring: _salvando,
                  child: Form(key: _form, child: widget.conteudo),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_aguardando)
            TextButton(
              onPressed: _sairEAguardar,
              child: const Text('Sair e aguardar'),
            )
          else
            TextButton(
              onPressed: _salvando ? null : _cancelar,
              child: const Text('Cancelar'),
            ),
          FilledButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: const Icon(Icons.check),
            label: Text(_salvando ? 'Salvando...' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}
