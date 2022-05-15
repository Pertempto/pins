import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/riverpod.dart';

import './map_state.dart';
import 'collection.dart';

final mapNotifierProvider = StateNotifierProvider<MapController, MapState>(
  (ref) => MapController(),
);

class MapController extends StateNotifier<MapState> {
  MapController({Collection? collection})
      : super(MapState(
          isLoading: true,
          pins: collection == null ? [] : collection.pins,
        ));

  setGoogleMapController(GoogleMapController? controller) {
    state = state.copyWith(mapController: controller);
  }

  setCurrentLocation({required LatLng currentLocation}) {
    if (state.isLoading) {
      state = state.copyWith(isLoading: false, currentLocation: currentLocation, targetLocation: currentLocation);
    } else {
      state = state.copyWith(currentLocation: currentLocation);
    }
  }

  goToMe() {
    _setTarget(state.currentLocation);
  }

  goTo(LatLng location) {
    _setTarget(location);
  }

  _setTarget(LatLng? location) {
    state = state.copyWith(targetLocation: location);
  }

  Future<void> moveCamera({double? zoom}) async {
    if (state.targetLocation == null) {
      return;
    }
    if (state.mapController != null) {
      zoom ??= await state.mapController!.getZoomLevel();
      // Shift camera position
      CameraPosition cameraPos = CameraPosition(target: state.targetLocation!, zoom: zoom);
      state.mapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      Future.delayed(Duration.zero, () => _setTarget(null));
    }
  }
}
