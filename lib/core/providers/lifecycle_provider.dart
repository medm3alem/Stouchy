import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/security/providers/security_provider.dart';

final appLifecycleProvider = Provider((ref) {
  return AppLifecycleObserver(ref);
});

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref _ref;

  AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On ne verrouille que si l'application passe totalement en arrière-plan (paused).
    // L'état 'inactive' (panneau de notifications, appels entrants) est ignoré pour éviter les verrouillages intempestifs.
    if (state == AppLifecycleState.paused) {
      _ref.read(securityProvider.notifier).lock();
    }
  }
}
