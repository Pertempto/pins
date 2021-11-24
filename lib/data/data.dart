import 'collection.dart';
import 'user.dart';

class Data {
  User? _user;
  Map<String, Collection> _collections = {};

  User? get currentUser {
    return _user;
  }

  bool get isSignedIn {
    return currentUser != null;
  }

  Map<String, Collection> get collections => _collections;

  Data.empty();

  updateCurrentUser(User? user) {
    _user = user;
  }

  updateCollections(Map<String, Collection> collections) {
    _collections = collections;
  }
}
