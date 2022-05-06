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

final userCollectionProvider = StreamProvider<Collection?>(
      (ref) {
    final userStream = ref.watch(authUserProvider);

    var user = userStream.value;

    if (user != null) {
      var docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      var userStream = docRef.snapshots().map((doc) => User.fromDocument(doc));
      return userStream.switchMap((user)  {
        var collectionDocRef = FirebaseFirestore.instance.collection('collections').doc(user.collectionIds[0]);
        return collectionDocRef.snapshots().map(Collection.fromDocument);
      });
    } else {
      return Stream.value(null);
    }
  },
);
//
// class UserData {
//   final Ref ref;
//   UserData(this.ref);
//
//   Stream<Collection?> currentCollection()  {
//     User? user = ref.watch(userProvider);
//     if (user != null) {
//       print('USER COLLECTIONS: ${user.collectionIds}');
//       var docRef =
//       FirebaseFirestore.instance.collection('collections').doc(user.collectionIds[0]);
//       return docRef.snapshots().map(Collection.fromDocument);
//     } else {
//       print('USER IS NULL!!!!');
//     }
//     return null;
//   }
// }
//
// final userCollectionsProvider = Provider<List<Collection>>((ref) {
//   final userStream = ref.watch(userProvider);
//   var user = userStream.value;
//   if (user != null) {
//     // TODO: actually get the collections.
//     return [];
//   } else {
//     return [];
//   }
// });
//
final userCurrentCollectionProvider = StreamProvider<Collection?>(
      (ref) {
    final user = ref
        .read(userProvider)
        .value;
    print('USER: $user');
    if (user != null && user.collectionIds.isNotEmpty) {
      print('GETTING COLLECTION');
      var docRef =
      FirebaseFirestore.instance.collection('collections').doc(user.collectionIds[0]);
      return docRef.snapshots().map(Collection.fromDocument);
    } else {
      print('USER: $user');
      return Stream.empty();
    }
  },
);
