import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class SecurityRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final LocalAuthentication _auth = LocalAuthentication();

  SecurityRepository(this._firestore, this._userId);

  DocumentReference get _userDoc {
    if (_userId == null) throw Exception("Utilisateur non connecté au service de sécurité");
    return _firestore.collection('users').doc(_userId);
  }

  Future<void> setPin(String pin) async {
    try {
      await _userDoc.set({'pin': pin}, SetOptions(merge: true));
    } catch (e) {
      print("Erreur Firestore setPin: $e");
      rethrow;
    }
  }

  Future<String?> getPin() async {
    if (_userId == null) return null;
    // On ne catch plus l'erreur ici, on la laisse remonter au notifier
    final doc = await _userDoc.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['pin'] as String?;
    }
    return null;
  }

  Future<void> removePin() async {
    if (_userId == null) return;
    // Utiliser update avec FieldValue.delete est plus propre pour supprimer un champ
    await _userDoc.update({'pin': FieldValue.delete()});
  }

  Future<bool> hasPin() async {
    final pin = await getPin();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    if (_userId == null) return;
    await _userDoc.set({'biometrics_enabled': enabled}, SetOptions(merge: true));
  }

  Future<bool> isBiometricsEnabled() async {
    if (_userId == null) return false;
    final doc = await _userDoc.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['biometrics_enabled'] == true;
    }
    return false;
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authentification requise pour accéder à Stouchy',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // INDISPENSABLE pour permettre au visage "faible" de fonctionner
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print("Erreur d'authentification: $e");
      // Si l'erreur est 'NotAvailable', c'est que la biométrie n'est pas configurée sur le tel
      return false;
    }
  }
}
