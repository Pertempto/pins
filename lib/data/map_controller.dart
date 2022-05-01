import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';

import './location_repository.dart';
import './map_state.dart';
import 'collection.dart';

final mapNotifierProvider = StateNotifierProvider<MapController, MapState>(
  (ref) => MapController(),
);

class MapController extends StateNotifier<MapState> {
  MapController({Collection? collection})
      : super(MapState(pins: collection == null ? [] : collection.pins));

  final repository = LocationRepository();

  void setGoogleMapController(GoogleMapController? controller) {
    state = state.copyWith(mapController: controller);
  }

  Future<void> getCurrentLocation() async {
    state = state.copyWith(isBusy: true);
    try {
      final data = await repository.getCurrentPosition();
      if (!mounted) return;
      state = state.copyWith(
          isBusy: false,
          currentLocation: LatLng(data.latitude, data.longitude));
    } on Exception catch (e, s) {
      debugPrint('login error: $e - stack: $s');
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
    }
  }

  Future<void> goToMe() async {
    await _setTarget(state.currentLocation);
  }

  Future<void> goTo(LatLng location) async {
    await _setTarget(location);
  }

  Future<void> _setTarget(LatLng? location) async {
    state = state.copyWith(targetLocation: location);
  }

  Future<void> moveCamera({double zoom = 15}) async {
    if (state.targetLocation == null) {
      return;
    }
    // Shift camera position
    CameraPosition cameraPos =
        CameraPosition(target: state.targetLocation!, zoom: zoom);
    if (state.mapController != null) {
      state.mapController!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      Future.delayed(Duration.zero, () => _setTarget(null));
    }
  }
}
