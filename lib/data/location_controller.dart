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

  void onMapCreated(GoogleMapController controller) {
    print('NEW MAP');
    state = state.copyWith(mapController: controller);
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

  Future<void> goToMe() async {
    await _setNewLocation(state.currentLocation);
    await _moveCamera(zoom: 18);
  }

  Future<void> _setNewLocation(LatLng location) async {
    state = state.copyWith(newLocation: location);
  }

  Future<void> _moveCamera({double zoom: 15}) async {
    // Set markers
    // final Set<Marker> _markers = {};
    // _markers.add(Marker(
    //     markerId: MarkerId(state.newLocation.toString()),
    //     position: state.newLocation,
    //     infoWindow: const InfoWindow(title: 'Remember Here', snippet: 'good place'),
    //     icon: BitmapDescriptor.defaultMarker));
    // state = state.copyWith(markers: _markers);

    // Shift camera position
    CameraPosition cameraPos = CameraPosition(target: state.newLocation, zoom: zoom);
    if (state.mapController != null) {
      state.mapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
    }
  }
}
