import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'data_store.dart';
import 'pin.dart';

class Collection {
  late String _collectionId;
  late String _name;
  late List<Pin> _pins;
  late List<String> _userIds;

  String get collectionId => _collectionId;

  String get name => _name;

  List<Pin> get pins => _pins;

  List<String> get userIds => _userIds;

  Map<String, dynamic> get dataMap {
    return {
      'name': _name,
      'pins': _pins.map((p) => p.dataMap).toList(),
      'userIds': _userIds,
    };
  }

  Collection.newCollection(this._collectionId, this._name, String userId)
      : _pins = [],
        _userIds = [userId] {
    saveData();
  }

  Collection.fromDocument(DocumentSnapshot documentSnapshot) {
    assert(documentSnapshot.exists);
    _collectionId = documentSnapshot.id;
    Map<String, dynamic> data = (documentSnapshot.data() as Map<String, dynamic>);
    _name = data['name'];
    _pins = [];
    for (Map<String, dynamic> pinData in data["pins"]) {
      _pins.add(Pin.fromMap(pinData));
    }
    _userIds = List.from(data['userIds']);
  }

  static Map<String, Collection> fromSnapshot(QuerySnapshot snapshot) {
    Map<String, Collection> collections = {};
    for (DocumentSnapshot documentSnapshot in snapshot.docs) {
      if (documentSnapshot.exists) {
        Collection collection = Collection.fromDocument(documentSnapshot);
        collections[collection.collectionId] = collection;
      }
    }
    return collections;
  }

  addPin(Pin pin) {
    if (!pins.map((p) => p.title == pin.title).any((b) => b)) {
      _pins.add(pin);
      saveData();
    }
  }

  saveData() {
    DataStore.setCollectionDoc(_collectionId, dataMap);
  }

  static String generateId() {
    String id = '';
    String options = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    Random rand = Random();
    for (int i = 0; i < 6; i++) {
      id += options[rand.nextInt(options.length)];
    }
    print('ID: $id');
    return id;
  }
}
