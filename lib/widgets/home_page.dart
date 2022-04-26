import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/location_controller.dart';
import '../data/pin.dart';
import '../providers.dart';
import 'settings.dart';

class HomePage extends HookConsumerWidget {
  HomePage({Key? key}) : super(key: key);

  final _pinFuture =
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(40, 72)), 'assets/icon/pin.png');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mapNotifier = ref.watch(mapNotifierProvider.notifier);
    final currentCollectionNotifier = ref.watch(userCurrentCollectionProvider);
    final currentPinIndex = useState(-1);
    final pinIcon = useFuture(useMemoized(() => _pinFuture), initialData: BitmapDescriptor.defaultMarker);
    useEffect(() {
      Future.microtask(() async => ref.watch(mapNotifierProvider.notifier).getCurrentLocation());
      return;
    }, const []);

    addPin(LatLng point) {
      currentCollectionNotifier!.createPin(point);
      currentPinIndex.value = currentCollectionNotifier.pins.length - 1;
    }

    deletePin() {
      currentCollectionNotifier!.removePin(currentPinIndex.value);
      currentPinIndex.value = -1;
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Pins'),
          actions: [
            // TODO: add collection screen
            IconButton(
              icon: const Icon(MdiIcons.playlistEdit),
              onPressed: () {},
              tooltip: 'View Collection',
            ),
            IconButton(
              icon: const Icon(MdiIcons.cog),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: mapState.isBusy
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.hybrid,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    initialCameraPosition: CameraPosition(target: mapState.currentLocation, zoom: 15),
                    markers: currentCollectionNotifier?.pins
                            .mapIndexed((i, p) => Marker(
                                position: p.position,
                                markerId: MarkerId(i.toString()),
                                anchor: const Offset(0, 1),
                                onTap: () => currentPinIndex.value = i,
                                zIndex: i.toDouble(),
                                icon: pinIcon.requireData))
                            .toSet() ??
                        {},
                    polylines: currentPinIndex.value == -1 || currentCollectionNotifier == null
                        ? {}
                        : {
                            Polyline(
                              polylineId: const PolylineId('CURRENT PIN LINE'),
                              points: [
                                currentCollectionNotifier.pins[currentPinIndex.value].position,
                                mapState.currentLocation,
                              ],
                              visible: true,
                              color: Colors.blue,
                              width: 5,
                              patterns: [PatternItem.dot, PatternItem.gap(20)],
                            ),
                          },
                    onMapCreated: mapNotifier.onMapCreated,
                    onLongPress: addPin,
                  ),
                  if (currentCollectionNotifier != null)
                    _pinView(
                      context,
                      currentPinIndex.value,
                      currentCollectionNotifier,
                      mapState.currentLocation,
                      addPin,
                      deletePin,
                    ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            currentPinIndex.value = -1;
            print(currentPinIndex.value);
            return mapNotifier.goToMe();
          },
          child: const Icon(MdiIcons.crosshairsGps),
        ));
  }

  Widget _pinView(BuildContext context, int selectedPinIndex, Collection selectedCollection, LatLng currentPosition,
      Function(LatLng) onAddPin, Function() onDeletePin) {
    TextTheme textTheme = Theme.of(context).textTheme;
    String title, note, subText;
    Widget buttonBar;
    if (selectedPinIndex == -1) {
      title = 'Here';
      note = '(${currentPosition.latitude.toStringAsFixed(4)}, ${currentPosition.longitude.toStringAsFixed(4)})';
      subText = 'Press and hold the map to add a pin.';
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
        // TODO: make this work
        // OutlinedButton.icon(
        //   onPressed: () {},
        //   icon: const Icon(MdiIcons.formatListBulleted),
        //   label: const Text('Select Pin'),
        // ),
        OutlinedButton.icon(
          onPressed: () => onAddPin(currentPosition),
          icon: const Icon(MdiIcons.mapMarkerPlus),
          label: const Text('Add Pin Here'),
        ),
      ]);
    } else {
      Pin pin = selectedCollection.pins[selectedPinIndex];
      title = pin.title;
      note = pin.note;
      double distanceMeters = Geolocator.distanceBetween(
          currentPosition.latitude, currentPosition.longitude, pin.position.latitude, pin.position.longitude);
      double distanceFeet = distanceMeters * 3.280839895;
      subText = 'Distance from here: ${distanceFeet.toStringAsFixed(1)} ft.';
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
        // TODO: make this work
        // OutlinedButton.icon(
        //   onPressed: () {},
        //   icon: const Icon(MdiIcons.formatListBulleted),
        //   label: const Text('Select Pin'),
        // ),
        // TODO: make this work
        // OutlinedButton.icon(
        //   onPressed: () {},
        //   icon: const Icon(MdiIcons.pencil),
        //   label: const Text('Edit'),
        // ),
        OutlinedButton.icon(
          onPressed: onDeletePin,
          icon: const Icon(MdiIcons.delete),
          label: const Text('Delete'),
        ),
      ]);
    }
    return SizedBox(
        width: double.infinity,
        child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: textTheme.headline6!),
                      const SizedBox(width: 16),
                      Text(note, style: textTheme.subtitle1!),
                      const Spacer(),
                    ],
                  ),
                  Text(subText, style: textTheme.subtitle1!),
                  buttonBar
                ],
              ),
            )));
  }
}
