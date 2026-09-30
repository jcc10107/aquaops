import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
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

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
    UserRole role = UserRole.customer,
    bool? hasOwnContainers,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;

    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      role: role,
      phone: phone,
      address: address,
      hasOwnContainers: hasOwnContainers,
    );

    await _firestore.createUser(user);
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Creates a Staff or Rider account on the owner's behalf. Runs the
  // Auth creation on a throwaway secondary Firebase App instance so it
  // doesn't sign the owner out of their own session (the client SDK
  // otherwise signs in as whichever user it just created).
  Future<UserModel> createTeamAccount({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? assignedArea,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'accountCreation-${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(email: email, password: password);
      final uid = credential.user!.uid;
      await secondaryAuth.signOut();

      final user = UserModel(
        id: uid,
        name: name,
        email: email,
        role: role,
        phone: phone,
        assignedArea: assignedArea,
      );
      await _firestore.createUser(user);
      return user;
    } finally {
      await secondaryApp.delete();
    }
  }
}
