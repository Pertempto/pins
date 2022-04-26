import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'pin.dart';

part 'map_state.freezed.dart';

@freezed
class MapState with _$MapState {
  const factory MapState({
    @Default(false) bool isBusy,
    @Default(LatLng(0, 0)) LatLng currentLocation,
    @Default(LatLng(0, 0)) LatLng newLocation,
    @Default([]) List<Pin> pins,
    String? errorMessage,
    GoogleMapController? mapController
  }) = _MapState;
}