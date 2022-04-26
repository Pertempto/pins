import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'data/collection.dart';
import 'data/user.dart';

final authUserProvider = StreamProvider<auth.User?>(
  (ref) => auth.FirebaseAuth.instance.authStateChanges(),
);

final userProvider = StreamProvider<User>(
  (ref) {
    final userStream = ref.watch(authUserProvider);

    var user = userStream.value;

    if (user != null) {
      var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      return docRef.snapshots().map((doc) => User.fromDocument(doc));
    } else {
      return const Stream.empty();
    }
  },
);

final collectionsProvider = StreamProvider<Map<String, Collection>>(
  (ref) {
    var docRef = FirebaseFirestore.instance.collection('collections');
    return docRef.snapshots().map((snapshot) => Collection.fromSnapshot(snapshot));
  },
);

final userCollectionsProvider = Provider<List<Collection>>(
  (ref) {
    final userStream = ref.watch(userProvider);
    var user = userStream.value;

    final collectionsStream = ref.watch(collectionsProvider);
    var collections = collectionsStream.value;

    if (user != null && collections != null) {
      return user.collectionIds
          .map((id) => collections[id])
          .where((collection) => collection != null && collection.userIds.contains(user.userId))
          .map((c) => c!)
          .toList();
    } else {
      return [];
    }
  },
);

final userCurrentCollectionProvider = Provider<Collection?>((ref) {
  final collections = ref.watch(userCollectionsProvider);
  Collection? collection;
  if (collections.isNotEmpty) {
    collection = collections[0];
  }
  return collection;
});
