import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'pin.dart';
import 'utils.dart';

part 'collection.g.dart';

const String owner = 'owner';
const String moderator = 'moderator';
const String member = 'member';
const String viewer = 'viewer';
const List<String> allRoles = [owner, moderator, member, viewer];
const Map<String, String> roleTitles = {
  owner: 'Owner',
  moderator: 'Moderator',
  member: 'Member',
  viewer: 'Viewer',
};

const Map<String, String> roleDescriptions = {
  owner: 'An owner has full control of a collection, including the ability to delete it.',
  moderator:
      'A moderator can edit the properties of a collection. They can also set the user roles of other users in the collection.',
  member: 'A member can add, edit, and view pins.',
  viewer: 'A viewer can only view pins. They have no edit access.',
};

@JsonSerializable(explicitToJson: true)
class Collection {
  late String collectionId;
  String name;
  List<Pin> pins;
  int pinCounter;
  Map<String, String> userRoles;

  List<String> get userIds => List.from(userRoles.keys);

  Collection({
    required this.collectionId,
    required this.name,
    this.pins = const [],
    this.pinCounter = 0,
    required this.userRoles,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  Collection.newCollection(this.name, String userId)
      : pins = [],
        pinCounter = 0,
        userRoles = {userId: owner} {
    collectionId = generateId(length: 6);
    saveData();
  }

  factory Collection.fromDocument(DocumentSnapshot documentSnapshot) {
    assert(documentSnapshot.exists);
    return Collection.fromJson(documentSnapshot.data() as Map<String, dynamic>);
  }

  // Check if a user has at least the owner role (delete the collection).
  bool isOwner(String userId) {
    return [owner].contains(getRole(userId));
  }

  // Check if a user has at least the moderator role (change the name, control user access).
  bool isModerator(String userId) {
    return [owner, moderator].contains(getRole(userId));
  }

  // Check if a user has at least the member role (add pins).
  bool isMember(String userId) {
    return [owner, moderator, member].contains(getRole(userId));
  }

  // Check if a user has at least the viewer role (add pins).
  bool isViewer(String userId) {
    return [owner, moderator, member, viewer].contains(getRole(userId));
  }

  // Get the user's role.
  String getRole(String userId) {
    return userRoles[userId] ?? '';
  }

  // Add a user as a viewer.
  addViewer(String userId) {
    if (isViewer(userId)) {
      return;
    }
    userRoles[userId] = viewer;
    saveData();
  }

  // Set the user's role.
  setRole(String userId, String role) {
    if (!isViewer(userId) || !allRoles.contains(role)) {
      return;
    }
    userRoles[userId] = role;
    saveData();
  }

  // Remove a user.
  removeUser(String userId) {
    if (!isViewer(userId)) {
      return;
    }
    userRoles.remove(userId);
    saveData();
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
}
