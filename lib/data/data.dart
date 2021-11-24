import 'user.dart';

class Data {
  User? _user;

  User? get currentUser {
    return _user;
  }

  bool get isSignedIn {
    return currentUser != null;
  }

  Data.empty();

  updateCurrentUser(User? user) {
    _user = user;
  }
}
