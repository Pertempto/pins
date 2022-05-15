import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'pin.dart';

part 'collection.g.dart';

@JsonSerializable(explicitToJson: true)
class Collection {
  late String collectionId;
  String name;
  List<Pin> pins;
  int pinCounter;
  List<String> ownerIds;
  List<String> viewerIds;
  List<String> blockedUserIds;

  Collection({
    required this.collectionId,
    required this.name,
    this.pins = const [],
    this.pinCounter = 0,
    required this.ownerIds,
    this.viewerIds = const [],
    this.blockedUserIds = const [],
  });

  factory Collection.fromJson(Map<String, dynamic> json) => _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  Collection.newCollection(this.name, String userId)
      : pins = [],
        pinCounter = 0,
        ownerIds = [userId],
        viewerIds = [],
        blockedUserIds = [] {
    collectionId = generateId();
    saveData();
  }

  factory Collection.fromDocument(DocumentSnapshot documentSnapshot) {
    assert(documentSnapshot.exists);
    return Collection.fromJson(documentSnapshot.data() as Map<String, dynamic>);
  }

  // Check if the collection has a pin with the given title.
  bool hasPinTitle(String title) {
    return pins.map((p) => p.title == title).any((b) => b);
  }

  // Create a new pin and add it to the collection.
  Pin createPin(LatLng position) {
    String title = '#${pinCounter + 1}';
    String note = '(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
    Pin pin = Pin(title: title, note: note, position: position);
    pins.add(pin);
    pinCounter++;
    saveData();
    return pin;
  }

  removePin(int index) {
    if (index >= 0 && index < pins.length) {
      pins.removeAt(index);
      saveData();
    }
  }

  saveData() {
    FirebaseFirestore.instance.collection('collections').doc(collectionId).set(toJson());
  }

  static String generateId() {
    String id = '';
    String options = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    Random rand = Random();
    for (int i = 0; i < 6; i++) {
      id += options[rand.nextInt(options.length)];
    }
    return id;
  }
}
