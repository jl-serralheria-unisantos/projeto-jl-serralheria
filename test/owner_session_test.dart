import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projeto_jl_serralheria/features/auth/owner_session.dart';

void main() {
  late StreamController<String?> session;
  late int privateBuilds;
  setUp(() {
    session = StreamController<String?>();
    privateBuilds = 0;
    addTearDown(session.close);
  });

  Widget app({
    String uid = 'owner',
    SignIn? login,
    Future<void> Function()? reload,
    Future<void> Function()? logout,
  }) => OwnerSession(
    ownerUid: uid,
    session: session.stream,
    reloadOwner: reload ?? () async {},
    signIn: login ?? (_, _) async => session.add(uid),
    signOut: logout ?? () async => session.add(null),
    authorizedApp: (_) {
      privateBuilds++;
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const Scaffold(body: Text('Orçamento privado')),
                ),
              ),
              child: const Text('Abrir orçamento'),
            ),
          ),
        ),
      );
    },
  );

  testWidgets(
    'restaura sessão sem exibir login e fecha rotas ao perder a sessão',
    (tester) async {
      await tester.pumpWidget(app());
      expect(find.text('Entrar'), findsNothing);
      expect(privateBuilds, 0);
      session.add('owner');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir orçamento'));
      await tester.pumpAndSettle();
      expect(find.text('Orçamento privado'), findsOneWidget);
      session.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Orçamento privado'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    },
  );

  for (final code in ['user-disabled', 'user-not-found']) {
    testWidgets('restauração rejeita $code antes de abrir dados', (
      tester,
    ) async {
      var signedOut = 0;
      await tester.pumpWidget(
        app(
          reload: () async => throw FirebaseAuthException(code: code),
          logout: () async {
            signedOut++;
            session.add(null);
          },
        ),
      );
      session.add('owner');
      await tester.pumpAndSettle();
      expect(privateBuilds, 0);
      expect(signedOut, 1);
      expect(find.text('Entrar'), findsOneWidget);
    });
  }

  testWidgets('retomada bloqueia a rota e remove a conta desativada', (
    tester,
  ) async {
    final pending = Completer<void>();
    var checks = 0;
    await tester.pumpWidget(
      app(reload: () => ++checks == 1 ? Future.value() : pending.future),
    );
    session.add('owner');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir orçamento'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('Orçamento privado'), findsNothing);
    expect(checks, 2);
    pending.completeError(FirebaseAuthException(code: 'user-disabled'));
    await tester.pumpAndSettle();
    expect(find.text('Orçamento privado', skipOffstage: false), findsNothing);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('falha de rede bloqueia sem sair e permite revalidar', (
    tester,
  ) async {
    var checks = 0;
    await tester.pumpWidget(
      app(
        reload: () async {
          if (++checks == 1) {
            throw FirebaseAuthException(code: 'network-request-failed');
          }
        },
        logout: () async => fail('Falha de rede encerrou sessão'),
      ),
    );
    session.add('owner');
    await tester.pumpAndSettle();
    expect(privateBuilds, 0);
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir orçamento'), findsOneWidget);
    expect(checks, 2);
  });

  testWidgets(
    'revalidações não se sobrepõem e resultado tardio após logout é descartado',
    (tester) async {
      final first = Completer<void>();
      final second = Completer<void>();
      var checks = 0;
      await tester.pumpWidget(
        app(reload: () => ++checks == 1 ? first.future : second.future),
      );
      session.add('owner');
      await tester.pump();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(checks, 1);
      first.complete();
      await tester.pump();
      expect(checks, 2);
      expect(privateBuilds, 0);
      session.add(null);
      await tester.pumpAndSettle();
      second.complete();
      await tester.pumpAndSettle();
      expect(find.text('Entrar'), findsOneWidget);
      expect(privateBuilds, 0);
    },
  );

  testWidgets(
    'retomada sem conexão oculta a edição e a recupera após revalidar',
    (tester) async {
      var checks = 0;
      await tester.pumpWidget(
        app(
          reload: () async {
            if (++checks == 2) {
              throw FirebaseAuthException(code: 'network-request-failed');
            }
          },
        ),
      );
      session.add('owner');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir orçamento'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Orçamento privado'), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Orçamento privado'), findsOneWidget);
      expect(checks, 3);
    },
  );

  testWidgets('outro UID é bloqueado e pode sair', (tester) async {
    await tester.pumpWidget(app());
    session.add('other');
    await tester.pumpAndSettle();
    expect(find.text('Esta conta não está autorizada.'), findsOneWidget);
    expect(privateBuilds, 0);
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Entrar'), findsOneWidget);
    expect(privateBuilds, 0);
  });

  testWidgets('UID ausente bloqueia acesso mesmo com sessão', (tester) async {
    await tester.pumpWidget(app(uid: ''));
    session.add('owner');
    await tester.pumpAndSettle();
    expect(find.textContaining('Configure o UID'), findsOneWidget);
    expect(privateBuilds, 0);
  });

  testWidgets('login trata senha inválida e conexão e permite tentar de novo', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        login: (email, password) async {
          expect(email, 'teste@example.test');
          expect(password, ' senha ');
          attempts++;
          if (attempts == 1) {
            throw FirebaseAuthException(code: 'invalid-credential');
          }
          if (attempts == 2) {
            throw FirebaseAuthException(code: 'network-request-failed');
          }
          session.add('owner');
        },
      ),
    );
    session.add(null);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      ' teste@example.test ',
    );
    await tester.enterText(find.byType(TextField).last, ' senha ');
    for (final message in [
      'E-mail ou senha inválidos.',
      'Verifique a conexão e tente novamente.',
      'Abrir orçamento',
    ]) {
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text(message), findsOneWidget);
    }
  });
}
