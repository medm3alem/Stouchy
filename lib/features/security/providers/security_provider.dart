import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../data/security_repository.dart';

final securityRepositoryProvider = Provider((ref) => SecurityRepository());

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
          isLocked: true,
          hasPin: false,
          biometricsEnabled: false,
          canUseBiometrics: false,
        )) {
    init();
  }

  Future<void> init() async {
    final hasPin = await _repo.hasPin();
    final bioEnabled = await _repo.isBiometricsEnabled();
    final canUseBio = await _repo.canCheckBiometrics();
    final available = await _repo.getAvailableBiometrics();
    
    state = state.copyWith(
      hasPin: hasPin,
      biometricsEnabled: bioEnabled,
      canUseBiometrics: canUseBio,
      availableBiometrics: available,
      isLocked: hasPin,
    );
  }

  Future<void> setPin(String pin) async {
    await _repo.setPin(pin);
    state = state.copyWith(hasPin: true);
  }

  Future<void> removePin() async {
    await _repo.removePin();
    state = state.copyWith(hasPin: false, isLocked: false);
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
