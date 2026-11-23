import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

typedef SignIn = Future<void> Function(String email, String password);

class OwnerSession extends StatefulWidget {
  const OwnerSession({
    super.key,
    required this.ownerUid,
    required this.session,
    required this.reloadOwner,
    required this.signIn,
    required this.signOut,
    required this.authorizedApp,
  });

  final String ownerUid;
  final Stream<String?> session;
  final Future<void> Function() reloadOwner;
  final SignIn signIn;
  final Future<void> Function() signOut;
  final WidgetBuilder authorizedApp;

  @override
  State<OwnerSession> createState() => _OwnerSessionState();
}

class _OwnerSessionState extends State<OwnerSession> {
  int _epoch = 0;
  late var _events = _sessionEvents();

  Stream<({String? uid, int epoch})> _sessionEvents() =>
      widget.session.distinct().map((uid) => (uid: uid, epoch: ++_epoch));

  @override
  void didUpdateWidget(OwnerSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _epoch++;
      _events = _sessionEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<({String? uid, int epoch})>(
      stream: _events,
      builder: (context, snapshot) {
        final Widget page;
        if (widget.ownerUid.isEmpty) {
          page = const Text(
            'Configure o UID do proprietário para acessar o aplicativo.',
          );
        } else if (snapshot.hasError) {
          page = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Falha ao verificar a sessão. Verifique a conexão e reabra o aplicativo.',
              ),
              SignOutButton(signOut: widget.signOut),
            ],
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          page = const CircularProgressIndicator();
        } else if (snapshot.data?.uid == widget.ownerUid) {
          final epoch = snapshot.requireData.epoch;
          return _VerifiedSession(
            key: ValueKey(epoch),
            owner: widget,
            isCurrent: () => _epoch == epoch,
          );
        } else if (snapshot.data?.uid != null) {
          page = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Esta conta não está autorizada.'),
              SignOutButton(signOut: widget.signOut),
            ],
          );
        } else {
          page = _LoginForm(signIn: widget.signIn);
        }
        return _AccessPage(child: page);
      },
    );
  }
}

class _AccessPage extends StatelessWidget {
  const _AccessPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const ValueKey('acesso'),
      title: 'JL Serralheria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2F6F63)),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedSession extends StatefulWidget {
  const _VerifiedSession({
    super.key,
    required this.owner,
    required this.isCurrent,
  });
  final bool Function() isCurrent;
  final OwnerSession owner;

  @override
  State<_VerifiedSession> createState() => _VerifiedSessionState();
}

class _VerifiedSessionState extends State<_VerifiedSession>
    with WidgetsBindingObserver {
  bool _inForeground = false;
  bool _checking = false;
  bool _unlocked = false;
  bool _keepPrivateTree = false;
  bool _revoked = false;
  int _generation = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _inForeground = state == null || state == AppLifecycleState.resumed;
    _validate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_inForeground == foreground) return;
    setState(() {
      _inForeground = foreground;
      _unlocked = false;
      _generation++;
    });
    if (foreground) _validate();
  }

  Future<void> _validate() async {
    if (!_inForeground || _checking || _revoked || !widget.isCurrent()) return;
    final generation = _generation;
    _checking = true;
    setState(() => _error = null);
    try {
      await widget.owner.reloadOwner();
      if (!mounted || !widget.isCurrent() || generation != _generation) return;
      setState(() {
        _unlocked = true;
        _keepPrivateTree = true;
      });
    } catch (e) {
      if (!mounted || !widget.isCurrent()) return;
      final code = e is FirebaseAuthException ? e.code : null;
      if (const {
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'invalid-user-token',
      }.contains(code)) {
        setState(() {
          _revoked = true;
          _keepPrivateTree = false;
          _unlocked = false;
          _error = 'Esta sessão perdeu o acesso. Entre novamente.';
        });
        try {
          await widget.owner.signOut();
        } catch (_) {
          // A sessão continua bloqueada e o botão Sair permite repetir.
        }
      } else if (generation == _generation) {
        setState(
          () => _error = code == 'network-request-failed'
              ? 'Sem conexão para verificar a conta. Reconecte e tente novamente.'
              : 'Não foi possível verificar a conta. Tente novamente.',
        );
      }
    } finally {
      _checking = false;
      if (mounted && generation != _generation && _inForeground && !_revoked) {
        _validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      fit: StackFit.expand,
      children: [
        if (_keepPrivateTree)
          Offstage(
            offstage: !_unlocked,
            child: ExcludeFocus(
              excluding: !_unlocked,
              child: TickerMode(
                enabled: _unlocked,
                child: Builder(builder: widget.owner.authorizedApp),
              ),
            ),
          ),
        if (!_unlocked)
          _AccessPage(
            child: _error == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      if (!_revoked)
                        TextButton(
                          onPressed: _validate,
                          child: const Text('Tentar novamente'),
                        ),
                      SignOutButton(signOut: widget.owner.signOut),
                    ],
                  ),
          ),
      ],
    );
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key, required this.signOut});
  final Future<void> Function() signOut;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Sair',
    icon: const Icon(Icons.logout),
    onPressed: () async {
      try {
        await signOut();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível sair. Tente novamente.'),
            ),
          );
        }
      }
    },
  );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.signIn});
  final SignIn signIn;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Informe o e-mail e a senha.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.signIn(email.text.trim(), password.text);
    } on FirebaseAuthException catch (e) {
      error = switch (e.code) {
        'network-request-failed' => 'Verifique a conexão e tente novamente.',
        'too-many-requests' =>
          'Muitas tentativas. Aguarde antes de tentar novamente.',
        'invalid-credential' ||
        'invalid-email' ||
        'wrong-password' ||
        'user-not-found' => 'E-mail ou senha inválidos.',
        _ => 'Não foi possível entrar. Verifique o acesso e tente novamente.',
      };
    } catch (_) {
      error = 'Não foi possível entrar. Tente novamente.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'JL Serralheria',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => submit(),
          decoration: const InputDecoration(labelText: 'Senha'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'Entrando…' : 'Entrar'),
        ),
      ],
    ),
  );
}
