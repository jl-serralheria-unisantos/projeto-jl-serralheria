import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/owner_session.dart';
import 'firebase_options.dart';
import 'shared/firebase_failure.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    FirebaseStartup(
      initialize: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        return ownerApp();
      },
    ),
  );
}

Widget ownerApp() {
  final auth = FirebaseAuth.instance;
  const uid = String.fromEnvironment('OWNER_UID');
  return OwnerSession(
    ownerUid: uid,
    session: auth.authStateChanges().map((user) => user?.uid),
    reloadOwner: () async {
      final user = auth.currentUser;
      if (user == null || user.uid != uid) throw StateError('Sessão alterada');
      await user.reload();
      if (auth.currentUser?.uid != uid) throw StateError('Sessão alterada');
    },
    signIn: (email, password) =>
        auth.signInWithEmailAndPassword(email: email, password: password),
    signOut: auth.signOut,
    authorizedApp: (_) => SerralheriaApp(onSignOut: auth.signOut),
  );
}

class FirebaseStartup extends StatefulWidget {
  const FirebaseStartup({super.key, required this.initialize});
  final Future<Widget> Function() initialize;

  @override
  State<FirebaseStartup> createState() => _FirebaseStartupState();
}

class _FirebaseStartupState extends State<FirebaseStartup> {
  late Future<Widget> _startup = _initialize();

  Future<Widget> _initialize() async {
    try {
      return await widget.initialize();
    } catch (error) {
      throw FirebaseFailure.forOperation(
        error,
        'Não foi possível iniciar o aplicativo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _startup,
    builder: (_, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return snapshot.requireData;
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child:
                snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(snapshot.error.toString()),
                      TextButton(
                        onPressed: () => setState(() {
                          _startup = _initialize();
                        }),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
