import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/pin.dart';

class PinView extends HookConsumerWidget {
  final Pin pin;
  final LatLng currentPosition;

  const PinView({
    Key? key,
    required this.pin,
    required this.currentPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String title = pin.title;
    String note = pin.note;
    double distanceMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        pin.position.latitude,
        pin.position.longitude);
    double distanceFeet = distanceMeters * 3.280839895;
    String subText =
        'Distance from here: ${distanceFeet.toStringAsFixed(1)} ft.';
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: textTheme.headline6!),
            const SizedBox(width: 16),
            Text(note, style: textTheme.subtitle1!),
          ],
        ),
        Text(subText, style: textTheme.subtitle1!),
      ],
    );
  }
}
