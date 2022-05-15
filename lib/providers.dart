import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'data/collection.dart';
import 'data/user.dart';

final authUserProvider = StreamProvider<auth.User?>(
  (ref) => auth.FirebaseAuth.instance.authStateChanges(),
);

final userProvider = StreamProvider<User?>(
  (ref) {
    final userStream = ref.watch(authUserProvider);

    var user = userStream.value;

    if (user != null) {
      var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      return docRef.snapshots().map((doc) => User.fromDocument(doc));
    } else {
      return Stream.value(null);
    }
  },
);

final userCollectionsProvider = StreamProvider<Iterable<Collection>?>(
  (ref) {
    final userStream = ref.watch(authUserProvider);
    var user = userStream.value;
    if (user != null) {
      var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      var userStream = docRef.snapshots().map((doc) => User.fromDocument(doc));
      return userStream.switchMap((user) {
        return FirebaseFirestore.instance
            .collection('collections')
            .where('viewerIds', arrayContains: user.userId)
            .snapshots()
            .map((snapshot) => snapshot.docs.map(Collection.fromDocument));
      });
    } else {
      return const Stream.empty();
    }
  },
);
