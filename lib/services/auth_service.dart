import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      return await _firestore.getUser(credential.user!.uid);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
