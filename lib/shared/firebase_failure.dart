import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseFailure implements Exception {
  const FirebaseFailure(this.message);
  final String message;

  factory FirebaseFailure.forOperation(Object error, String fallback) {
    final code = error is FirebaseException ? error.code : null;
    if (kDebugMode) debugPrint('Firebase: ${code ?? error.runtimeType}');
    return FirebaseFailure(switch (code) {
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
        'Conexão indisponível. Verifique a internet e tente novamente.',
      'permission-denied' || 'unauthenticated' =>
        'Acesso aos dados negado. Confira a conta e as permissões.',
      _ => fallback,
    });
  }

  @override
  String toString() => message;
}
