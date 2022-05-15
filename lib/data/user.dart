import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'collection.dart';

class User {
  late String _userId;
  late String _name;
  late String? _currentCollectionId;

  String get userId => _userId;

  String get name => _name;

  String? get currentCollectionId => _currentCollectionId;

  Map<String, dynamic> get dataMap {
    return {
      'name': _name,
      'currentCollectionId': _currentCollectionId,
    };
  }

  User.newUser(this._userId, this._name) {
    Collection collection = Collection.newCollection('My Pins', _userId);
    _currentCollectionId = collection.collectionId;
    saveData();
  }

  User.fromDocument(DocumentSnapshot documentSnapshot) {
    if (kDebugMode) {
      print("loading user...");
    }
    assert(documentSnapshot.exists);
    _userId = documentSnapshot.id;
    Map<String, dynamic> dataMap = (documentSnapshot.data() as Map<String, dynamic>);
    _name = dataMap['name'];
    _currentCollectionId = dataMap['currentCollectionId'];
    if (kDebugMode) {
      print("done loading user");
    }
  }

  static Map<String, User> usersFromSnapshot(QuerySnapshot snapshot) {
    Map<String, User> users = {};
    for (DocumentSnapshot documentSnapshot in snapshot.docs) {
      if (documentSnapshot.exists) {
        User user = User.fromDocument(documentSnapshot);
        users[user.userId] = user;
      }
    }
    return users;
  }

  selectCollection(String collectionId) {
    _currentCollectionId = collectionId;
    saveData();
  }

  saveData() {
    FirebaseFirestore.instance.collection('users').doc(_userId).set(dataMap);
  }
}
