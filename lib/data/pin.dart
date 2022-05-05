import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'pin.freezed.dart';
part 'pin.g.dart';

@freezed
class Pin with _$Pin {
  const factory Pin({
    required String title,
    required String note,
    @LatLngConvertor() required LatLng position,
  }) = _Pin;

  factory Pin.fromJson(Map<String, dynamic> json) => _$PinFromJson(json);
}

class LatLngConvertor implements JsonConverter<LatLng, List<double>> {
  const LatLngConvertor();

  @override
  LatLng fromJson(List<double> coordinates) {
    return LatLng(coordinates[0], coordinates[1]);
  }

  @override
  List<double> toJson(LatLng point) => [point.latitude, point.longitude];
}
