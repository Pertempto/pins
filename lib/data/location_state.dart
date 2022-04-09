import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'location_state.freezed.dart';

@freezed
class LocationState with _$LocationState {
  const factory LocationState({
    @Default(false) bool isBusy,
    @Default(LatLng(35.658034, 139.701636)) LatLng currentLocation,
    @Default(LatLng(35.658034, 139.701636)) LatLng newLocation,
    @Default({}) Set<Marker> markers,
    String? errorMessage,
  }) = _LocationState;
}