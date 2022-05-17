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

@JsonSerializable(explicitToJson: true)
class Collection {
  late String collectionId;
  String name;
  List<Pin> pins;
  int pinCounter;
  Map<String, String> _userRoles;
  List<String> ownerIds;
  List<String> viewerIds;

  Collection({
    required this.collectionId,
    required this.name,
    this.pins = const [],
    this.pinCounter = 0,
    Map<String, String> userRoles = const {},
    required this.ownerIds,
    this.viewerIds = const [],
  }) : _userRoles = userRoles;

  factory Collection.fromJson(Map<String, dynamic> json) => _$CollectionFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionToJson(this);

  Collection.newCollection(this.name, String userId)
      : pins = [],
        pinCounter = 0,
        _userRoles = {userId: owner},
        ownerIds = [userId],
        viewerIds = [userId] {
    collectionId = generateId(length: 6);
    saveData();
  }

  factory Collection.fromDocument(DocumentSnapshot documentSnapshot) {
    assert(documentSnapshot.exists);
    return Collection.fromJson(documentSnapshot.data() as Map<String, dynamic>);
  }

  // Check if a user has at least the owner role (delete the collection).
  bool isOwner(String userId) {
    return ownerIds.contains(userId);
    return [owner].contains(getRole(userId));
  }

  // Check if a user has at least the moderator role (change the name, control user access).
  bool isModerator(String userId) {
    return ownerIds.contains(userId);
    return [owner, moderator].contains(getRole(userId));
  }

  // Check if a user has at least the member role (add pins).
  bool isMember(String userId) {
    return ownerIds.contains(userId);
    return [owner, moderator, member].contains(getRole(userId));
  }

  // Check if a user has at least the viewer role (add pins).
  bool isViewer(String userId) {
    return viewerIds.contains(userId);
    return [owner, moderator, member, viewer].contains(getRole(userId));
  }

  // Get the user's role.
  String getRole(String userId) {
    return _userRoles[userId] ?? '';
  }

  // Add a user as a viewer.
  addViewer(String userId) {
    if (viewerIds.contains(userId)) {
      return;
    }
    viewerIds.add(userId);
    saveData();
  }

  // Add a user as an owner. They must already be a viewer.
  giveEditAccess(String userId) {
    if (!viewerIds.contains(userId)) {
      return;
    }
    ownerIds.add(userId);
    saveData();
  }

  // Demote an owner to viewer.
  removeEditAccess(String userId) {
    if (!ownerIds.contains(userId)) {
      return;
    }
    ownerIds.remove(userId);
    saveData();
  }

  // Remove a user.
  removeUser(String userId) {
    if (!viewerIds.contains(userId)) {
      return;
    }
    // If they are a owner, remove them from that too.
    ownerIds.remove(userId);
    viewerIds.remove(userId);
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
