import 'collection.dart';
import 'user.dart';

class Data {
  User? _user;
  Map<String, Collection> _collections = {};
  bool _isLoadingUser = true;
  bool _isLoadingCollections = true;

  User? get currentUser => _user;

  bool get isSignedIn => currentUser != null;

  Map<String, Collection> get collections => _collections;

  bool get isLoading => _isLoadingUser | _isLoadingCollections;

  Data.empty();

  updateCurrentUser(User? user) {
    _user = user;
    _isLoadingUser = false;
  }

  updateCollections(Map<String, Collection> collections) {
    _collections = collections;
    _isLoadingCollections = false;
  }
}
