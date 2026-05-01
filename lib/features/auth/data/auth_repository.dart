import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository(FirebaseAuth.instance));

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  AuthRepository(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUp({required String email, required String password}) async {
    try {
      print("Tentative d'inscription pour: $email");
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print("Inscription réussie pour: ${credential.user?.uid}");
      return credential;
    } on FirebaseAuthException catch (e) {
      print("Erreur Firebase Auth (${e.code}): ${e.message}");
      throw _handleAuthException(e);
    } catch (e) {
      print("Erreur inconnue lors de l'inscription: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Utilisateur non trouvé.');
      case 'wrong-password':
        return Exception('Mot de passe incorrect.');
      case 'email-already-in-use':
        return Exception('Cet email est déjà utilisé.');
      case 'weak-password':
        return Exception('Le mot de passe est trop faible.');
      case 'invalid-email':
        return Exception('Format d\'email invalide.');
      default:
        return Exception(e.message ?? 'Une erreur d\'authentification est survenue.');
    }
  }
}
