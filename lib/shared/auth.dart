import 'package:firebase_auth/firebase_auth.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Stream get stream {
    return _firebaseAuth.authStateChanges();
  }

  User? get user {
    return _firebaseAuth.currentUser;
  }

  Future<String> signIn(String email, String password) async {
    UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    if (result.user == null) {
      return "";
    }
    return result.user!.uid;
  }

  Future<void> signOut() async {
    _firebaseAuth.signOut();
  }

  Future<String> signUp(String email, String password) async {
    UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (result.user == null) {
      return "";
    }
    return result.user!.uid;
  }
}
