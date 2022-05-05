import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'collection.dart';

class User {
  late String _userId;
  late String _name;
  late List<String> _collectionIds;

  String get userId => _userId;

  String get name => _name;

  List<String> get collectionIds => _collectionIds;

  Map<String, dynamic> get dataMap {
    return {
      'name': _name,
      'collectionIds': _collectionIds,
    };
  }

  User.newUser(this._userId, this._name) : _collectionIds = [] {
    Collection collection = Collection.newCollection('My Pins', _userId);
    _collectionIds.add(collection.collectionId);
    saveData();
  }

  User.fromDocument(DocumentSnapshot documentSnapshot) {
    if (kDebugMode) {
      print("loading user...");
    }
    assert(documentSnapshot.exists);
    _userId = documentSnapshot.id;
    Map<String, dynamic> dataMap =
        (documentSnapshot.data() as Map<String, dynamic>);
    _name = dataMap['name'];
    _collectionIds = List.from(dataMap['collectionIds']);
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

  addCollection(String collectionId) {
    _collectionIds.insert(0, collectionId);
    saveData();
  }

  selectCollection(String collectionId) {
    if (_collectionIds.remove(collectionId)) {
      _collectionIds.insert(0, collectionId);
      saveData();
    }
  }

  saveData() {
    FirebaseFirestore.instance.collection('users').doc(_userId).set(dataMap);
  }
}
