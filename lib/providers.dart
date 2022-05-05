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

getCollectionProvider(String collectionId) {
  return StreamProvider<Collection?>((ref) {
    var docRef =
        FirebaseFirestore.instance.collection('collections').doc(collectionId);
    return docRef.snapshots().map(Collection.fromDocument);
  });
}

final userCollectionsProvider = Provider<List<Collection>>((ref) {
  final userStream = ref.watch(userProvider);
  var user = userStream.value;
  if (user != null) {
    // TODO: actually get the collections.
    return [];
  } else {
    return [];
  }
});

final userCurrentCollectionProvider = Provider<Collection?>(
  (ref) {
    final userStream = ref.watch(userProvider);
    var user = userStream.value;
    if (user != null && user.collectionIds.isNotEmpty) {
      print('GETTING COLLECTION');
      final StreamProvider provider =
          getCollectionProvider(user.collectionIds[0]);
      final result = ref.watch(provider);
      print('RESULT: $result');
      return result.value;
    } else {
      print('USER: $user');
      return null;
    }
  },
);
