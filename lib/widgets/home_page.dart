import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/location_controller.dart';
import '../data/pin.dart';
import '../providers.dart';
import 'pin_view.dart';
import 'settings.dart';

class HomePage extends HookConsumerWidget {
  HomePage({Key? key}) : super(key: key);

  final _locationIconFuture = BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(72, 72)), 'assets/icon/location.png');

  final _pinIconFuture = BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(40, 72)), 'assets/icon/pin.png');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mapNotifier = ref.watch(mapNotifierProvider.notifier);
    final currentCollectionNotifier = ref.watch(userCurrentCollectionProvider);
    final currentPinIndex = useState(-1);
    if (currentCollectionNotifier != null &&
        currentPinIndex.value >= currentCollectionNotifier.pins.length) {
      currentPinIndex.value = -1;
    }
    final locationIcon = useFuture(useMemoized(() => _locationIconFuture),
        initialData: BitmapDescriptor.defaultMarker);
    final pinIcon = useFuture(useMemoized(() => _pinIconFuture),
        initialData: BitmapDescriptor.defaultMarker);
    useEffect(() {
      Future.microtask(() async =>
          ref.watch(mapNotifierProvider.notifier).getCurrentLocation());
      return;
    }, const []);

    addPin(LatLng point) {
      currentCollectionNotifier!.createPin(point);
      currentPinIndex.value = currentCollectionNotifier.pins.length - 1;
    }

    deletePin() {
      currentCollectionNotifier!.removePin(currentPinIndex.value);
      currentPinIndex.value = -1;
      mapNotifier.goToMe();
    }

    Set<Marker> markers = currentCollectionNotifier?.pins
            .mapIndexed((i, p) => Marker(
                position: p.position,
                markerId: MarkerId(i.toString()),
                anchor: const Offset(0, 1),
                onTap: () => currentPinIndex.value = i,
                zIndex: i.toDouble(),
                icon: pinIcon.requireData))
            .toSet() ??
        {};
    markers.add(Marker(
        position: mapState.currentLocation,
        markerId: const MarkerId('position'),
        icon: locationIcon.requireData,
        anchor: const Offset(0.5, 0.5),
        onTap: () => currentPinIndex.value = -1,
        zIndex: markers.length.toDouble()));

    return Scaffold(
        appBar: AppBar(
          title: Text(currentCollectionNotifier == null
              ? 'Pins'
              : currentCollectionNotifier.name),
          actions: [
            // TODO: add collection screen
            IconButton(
              icon: const Icon(MdiIcons.playlistEdit),
              onPressed: () {},
              tooltip: 'View Collection',
            ),
            IconButton(
              icon: const Icon(MdiIcons.cog),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const Settings())),
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
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    initialCameraPosition: CameraPosition(
                        target: mapState.currentLocation, zoom: 15),
                    markers: markers,
                    polylines: currentPinIndex.value == -1 ||
                            currentCollectionNotifier == null
                        ? {}
                        : {
                            Polyline(
                              polylineId: const PolylineId('CURRENT PIN LINE'),
                              points: [
                                currentCollectionNotifier
                                    .pins[currentPinIndex.value].position,
                                mapState.currentLocation,
                              ],
                              visible: true,
                              color: Colors.blue,
                              width: 5,
                              patterns: [PatternItem.dot, PatternItem.gap(20)],
                            ),
                          },
                    onMapCreated: mapNotifier.onMapCreated,
                    onTap: (_) => currentPinIndex.value = -1,
                    onLongPress: addPin,
                  ),
                  if (currentCollectionNotifier != null)
                    _pinView(
                      context: context,
                      selectedPinIndex: currentPinIndex.value,
                      selectedCollection: currentCollectionNotifier,
                      currentPosition: mapState.currentLocation,
                      onSelectPin: () => _selectPinDialog(
                        context: context,
                        collection: currentCollectionNotifier,
                        onSelected: (index) => currentPinIndex.value = index,
                      ),
                      onAddPin: addPin,
                      onDeletePin: deletePin,
                    ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            currentPinIndex.value = -1;
            mapNotifier.goToMe();
          },
          child: const Icon(MdiIcons.crosshairsGps),
        ));
  }

  Widget _pinView({
    required BuildContext context,
    required int selectedPinIndex,
    required Collection selectedCollection,
    required LatLng currentPosition,
    Function()? onSelectPin,
    Function(LatLng)? onAddPin,
    Function()? onDeletePin,
  }) {
    TextTheme textTheme = Theme.of(context).textTheme;
    Widget content;
    Widget buttonBar;
    if (selectedPinIndex == -1) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Here', style: textTheme.headline6!),
              const SizedBox(width: 16),
              Text(
                  '(${currentPosition.latitude.toStringAsFixed(4)}, ${currentPosition.longitude.toStringAsFixed(4)})',
                  style: textTheme.subtitle1!),
              const Spacer(),
            ],
          ),
          Text('Press and hold the map to add a pin.',
              style: textTheme.subtitle1!),
        ],
      );
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
        OutlinedButton.icon(
          onPressed: onSelectPin,
          icon: const Icon(MdiIcons.formatListBulleted),
          label: const Text('Select Pin'),
        ),
        OutlinedButton.icon(
          onPressed: onAddPin != null ? () => onAddPin(currentPosition) : null,
          icon: const Icon(MdiIcons.mapMarkerPlus),
          label: const Text('Add Pin Here'),
        ),
      ]);
    } else {
      Pin pin = selectedCollection.pins[selectedPinIndex];
      content = PinView(pin: pin, currentPosition: currentPosition);
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
        OutlinedButton.icon(
          onPressed: onSelectPin,
          icon: const Icon(MdiIcons.formatListBulleted),
          label: const Text('Select Pin'),
        ),
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
                  children: [content, buttonBar],
                ))));
  }

  _selectPinDialog({
    required BuildContext context,
    required Collection collection,
    required Function(int index) onSelected,
  }) {
    TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade300,
          title: const Text('Select Pin'),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...collection.pins.mapIndexed(
                  (index, pin) => GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                      ),
                      child: Row(
                        children: [
                          Text(pin.title, style: textTheme.headlineSmall),
                          const Spacer(),
                          Text(pin.note, style: textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSelected(index);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
