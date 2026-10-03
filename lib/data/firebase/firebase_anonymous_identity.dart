import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:score_tracker/domain/repositories/room_repository.dart';

class FirebaseAnonymousIdentity {
  FirebaseAnonymousIdentity({this.auth});

  final FirebaseAuth? auth;

  FirebaseAuth get _firebaseAuth => auth ?? FirebaseAuth.instance;

  Future<String> requireUserId() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) return currentUser.uid;

      final credential = await _firebaseAuth.signInAnonymously();
      final userId = credential.user?.uid;
      if (userId == null) {
        throw StateError('Anonymous sign-in did not return a user.');
      }
      return userId;
    } on FirebaseAuthException catch (error) {
      final code = switch (error.code) {
        'operation-not-allowed' ||
        'admin-restricted-operation' => 'anonymous_auth_disabled',
        'network-request-failed' => 'network_unavailable',
        _ => 'auth_${error.code.replaceAll('-', '_')}',
      };
      throw RoomRepositoryException(code);
    } on FirebaseException catch (error) {
      final code = error.code.toLowerCase();
      throw RoomRepositoryException(
        code.contains('no-app') ? 'firebase_not_initialized' : 'auth_error',
      );
    }
  }
}
