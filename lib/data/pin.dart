import 'package:google_maps_flutter/google_maps_flutter.dart';

class Pin {
  late String _title;
  late String _note;
  late LatLng _position;

  String get title => _title;

  String get note => _note;

  LatLng get position => _position;

  Map<String, dynamic> get dataMap {
    return {
      'title': _title,
      'note': _note,
      'lat': _position.latitude,
      'lng': _position.longitude,
    };
  }

  Pin(this._title, this._note, this._position);

  Pin.fromMap(Map<String, dynamic> data) {
    _title = data['title'];
    _note = data['note'];
    _position = LatLng(data['lat'], data['lng']);
  }
}
