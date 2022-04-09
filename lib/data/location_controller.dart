import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';

import './location_repository.dart';
import './location_state.dart';

final locationNotifierProvider = StateNotifierProvider<LocationController, LocationState>(
  (ref) => LocationController(),
);

class LocationController extends StateNotifier<LocationState> {
  LocationController() : super(const LocationState());

  final repository = LocationRepository();
  final Completer<GoogleMapController> _mapController = Completer();

  void onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isBusy: true);
    try {
      final data = await repository.getCurrentPosition();
      state = state.copyWith(isBusy: false, currentLocation: LatLng(data.latitude, data.longitude));
    } on Exception catch (e, s) {
      debugPrint('login error: $e - stack: $s');
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> getNewLocation() async {
    await _setNewLocation();
    await _setMaker();
  }

  Future<void> _setNewLocation() async {
    state = state.copyWith(newLocation: const LatLng(35.658034, 139.701636));
  }

  Future<void> _setMaker() async {
    // Set markers
    final Set<Marker> _markers = {};
    _markers.add(Marker(
        markerId: MarkerId(state.newLocation.toString()),
        position: state.newLocation,
        infoWindow: const InfoWindow(title: 'Remember Here', snippet: 'good place'),
        icon: BitmapDescriptor.defaultMarker));
    state = state.copyWith(markers: _markers);

    // Shift camera position
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(state.newLocation));
  }
}
