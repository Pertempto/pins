import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../data/user.dart';
import '../shared/auth.dart';
import 'collection.dart';
import 'data.dart';

class DataStore {
  static bool _isLoading = false;
  static late Auth _auth;
  static CollectionReference _collectionsCollection = FirebaseFirestore.instance.collection('collections');
  static StreamSubscription? _userStreamSubscription;
  static final StreamController _streamController = StreamController.broadcast();
  static late Stream _dataStream;
  static Data data = Data.empty();

  static Auth get auth => _auth;

  static bool get isLoading => _isLoading;

  static init() {
    _auth = Auth();
    _dataStream = _streamController.stream;
    if (_auth.user != null) {
      print('already signed in...');
      updateUserConnection(_auth.user!.uid);
      _streamController.add('auth');
    }
    _auth.stream.listen((event) {
      print('DATASTORE - got auth update');
      updateUserConnection(event == null ? '' : event.uid);
      _streamController.add('auth');
    });
    _collectionsCollection.snapshots().listen((event) {
      data.updateCollections(Collection.fromSnapshot(event));
      _streamController.add('collections');
    });
  }

  static StreamBuilder dataWrap(Widget Function() callback) {
    return StreamBuilder(
      stream: _dataStream,
      builder: (context, event) {
        print('user now: ${data.currentUser}');
        return callback();
      },
    );
  }

  static updateUserConnection(String userId) {
    print('USER ID: $userId');
    if (userId.isEmpty) {
      if (_userStreamSubscription != null) {
        _userStreamSubscription!.cancel();
      }
      data.updateCurrentUser(null);
    } else {
      _userStreamSubscription = FirebaseFirestore.instance.collection('users').doc(userId).snapshots().listen((doc) {
        print('DATASTORE - got user update');
        data.updateCurrentUser(User.fromDocument(doc));
        _streamController.add('users');
      }, onError: (error) {
        print('user stream error: $error');
      });
    }
    _isLoading = false;
  }

  static setUserDoc(String userId, Map<String, dynamic> dataMap) {
    FirebaseFirestore.instance.collection('users').doc(userId).set(dataMap);
  }

  static setCollectionDoc(String collectionId, Map<String, dynamic> dataMap) {
    FirebaseFirestore.instance.collection('collections').doc(collectionId).set(dataMap);
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
