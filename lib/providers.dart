import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'data/collection.dart';
import 'data/collection_request.dart';
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

final allUsersProvider = StreamProvider<Map<String, User>>(
  (ref) {
    final userStream = ref.watch(authUserProvider);
    if (userStream.value != null) {
      var collectionRef = FirebaseFirestore.instance.collection('users');
      return collectionRef.snapshots().map((docs) {
        Map<String, User> users = {};
        for (DocumentSnapshot doc in docs.docs) {
          User user = User.fromDocument(doc);
          users[user.userId] = user;
        }
        return users;
      });
    } else {
      return Stream.value({});
    }
  },
);

final collectionRequestsProvider = StreamProvider.autoDispose.family<Iterable<CollectionRequest>, String>(
    (ref, collectionId) {
      return FirebaseFirestore.instance
          .collection('collectionRequests')
          .where('collectionId', isEqualTo: collectionId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(CollectionRequest.fromDocument));
    }
);

final userCollectionRequestsProvider = StreamProvider.autoDispose.family<Iterable<CollectionRequest>, String>(
        (ref, userId) {
      return FirebaseFirestore.instance
          .collection('collectionRequests')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(CollectionRequest.fromDocument));
    }
);