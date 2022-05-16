import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'utils.dart';

part 'collection_request.g.dart';

@JsonSerializable()
class CollectionRequest {
  String requestId;
  String collectionId;
  String userId;

  CollectionRequest({
    required this.requestId,
    required this.collectionId,
    required this.userId,
  });

  factory CollectionRequest.fromJson(Map<String, dynamic> json) => _$CollectionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionRequestToJson(this);

  CollectionRequest.newRequest(this.collectionId, this.userId) : requestId = generateId(length: 12) {
    saveData();
  }

  factory CollectionRequest.fromDocument(DocumentSnapshot documentSnapshot) {
    assert(documentSnapshot.exists);
    return CollectionRequest.fromJson(documentSnapshot.data() as Map<String, dynamic>);
  }

  saveData() {
    FirebaseFirestore.instance.collection('collectionRequests').doc(requestId).set(toJson());
  }

  delete() {
    FirebaseFirestore.instance.collection('collectionRequests').doc(requestId).delete();
  }
}
