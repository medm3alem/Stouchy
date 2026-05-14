import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../data/security_repository.dart';
import '../../auth/data/auth_repository.dart';

final securityRepositoryProvider = Provider((ref) {
  // On surveille l'état de l'utilisateur (on utilise .value pour avoir l'objet User)
  final user = ref.watch(authStateProvider).value;
  return SecurityRepository(FirebaseFirestore.instance, user?.uid);
});

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final repo = ref.watch(securityRepositoryProvider);
  return SecurityNotifier(repo);
});

class SecurityState {
  final bool isLocked;
  final bool hasPin;
  final bool biometricsEnabled;
  final bool canUseBiometrics;
  final List<BiometricType> availableBiometrics;

  SecurityState({
    required this.isLocked,
    required this.hasPin,
    required this.biometricsEnabled,
    required this.canUseBiometrics,
    this.availableBiometrics = const [],
  });

  bool get hasFace => availableBiometrics.contains(BiometricType.face) || 
                      availableBiometrics.contains(BiometricType.strong) ||
                      availableBiometrics.contains(BiometricType.weak);

  SecurityState copyWith({
    bool? isLocked,
    bool? hasPin,
    bool? biometricsEnabled,
    bool? canUseBiometrics,
    List<BiometricType>? availableBiometrics,
  }) {
    return SecurityState(
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecurityRepository _repo;

  SecurityNotifier(this._repo)
      : super(SecurityState(
          isLocked: true, // Verrouillé par défaut pour la sécurité
          hasPin: false,
          biometricsEnabled: false,
          canUseBiometrics: false,
        )) {
    init();
  }

  Future<void> init() async {
    try {
      final hasPin = await _repo.hasPin();
      final bioEnabled = await _repo.isBiometricsEnabled();
      final canUseBio = await _repo.canCheckBiometrics();
      final available = await _repo.getAvailableBiometrics();
      
      state = state.copyWith(
        hasPin: hasPin,
        biometricsEnabled: bioEnabled,
        canUseBiometrics: canUseBio,
        availableBiometrics: available,
        // On ne déverrouille QUE si on a la certitude qu'il n'y a pas de PIN
        isLocked: hasPin, 
      );
    } catch (e) {
      print("Erreur initialisation sécurité: $e");
      // En cas d'erreur (ex: permission denied), on reste verrouillé par prudence
      // On met hasPin à true pour forcer l'affichage de l'écran Lock
      state = state.copyWith(isLocked: true, hasPin: true);
    }
  }

  Future<void> setPin(String pin) async {
    // Mise à jour instantanée de l'interface (Optimistic UI)
    state = state.copyWith(hasPin: true);
    try {
      await _repo.setPin(pin);
    } catch (e) {
      // En cas d'erreur réelle, on annule le changement visuel
      state = state.copyWith(hasPin: false);
      print("Erreur setPin: $e");
      rethrow;
    }
  }

  Future<void> removePin() async {
    // Mise à jour instantanée de l'interface
    state = state.copyWith(hasPin: false, isLocked: false);
    try {
      await _repo.removePin();
    } catch (e) {
      // En cas d'erreur, on remet l'état précédent
      state = state.copyWith(hasPin: true);
      print("Erreur removePin: $e");
      rethrow;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await _repo.setBiometricsEnabled(enabled);
    state = state.copyWith(biometricsEnabled: enabled);
  }

  Future<bool> verifyPin(String pin) async {
    final savedPin = await _repo.getPin();
    if (savedPin == pin) {
      unlock();
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometrics() async {
    if (state.canUseBiometrics && state.biometricsEnabled) {
      final success = await _repo.authenticateWithBiometrics();
      if (success) {
        unlock();
      }
      return success;
    }
    return false;
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }
}
