import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/map_controller.dart';
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
    final mapController = ref.watch(mapNotifierProvider.notifier);
    final user = ref.watch(userProvider);
    final currentCollectionNotifier = ref.watch(userCurrentCollectionProvider);
    final currentPinIndexNotifier = useState(-1);
    final showMap = useState(true);

    TextTheme textTheme = Theme.of(context).textTheme;
    List<Widget> actions = [];
    Widget content;
    print('COLLECTIONS: ${user.value?.collectionIds ?? []}');
    if (currentCollectionNotifier == null) {
      content = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have no collections.', style: textTheme.headlineSmall),
            ElevatedButton.icon(
              onPressed: () {
                Collection collection =
                    Collection.newCollection('TEST!', user.value!.userId);
                user.value!.addCollection(collection.collectionId);
              },
              label: const Text('Create Collection'),
              icon: const Icon(MdiIcons.playlistPlus),
            ),
          ],
        ),
      );
    } else {
      if (currentPinIndexNotifier.value >=
          currentCollectionNotifier.pins.length) {
        currentPinIndexNotifier.value = -1;
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

      if (mapState.targetLocation != null) {
        if (kDebugMode) {
          print('MOVING CAMERA TO TARGET');
        }
        mapController.moveCamera();
      }

      addPin(LatLng point) {
        currentCollectionNotifier.createPin(point);
        currentPinIndexNotifier.value =
            currentCollectionNotifier.pins.length - 1;
      }

      deletePin() {
        currentCollectionNotifier.removePin(currentPinIndexNotifier.value);
        currentPinIndexNotifier.value = -1;
        mapController.goToMe();
      }

      Set<Marker> markers = currentCollectionNotifier.pins
          .mapIndexed((i, p) => Marker(
              position: p.position,
              markerId: MarkerId(i.toString()),
              anchor: const Offset(0, 1),
              onTap: () => currentPinIndexNotifier.value = i,
              zIndex: i.toDouble(),
              icon: pinIcon.requireData))
          .toSet();
      markers.add(Marker(
          position: mapState.currentLocation,
          markerId: const MarkerId('position'),
          icon: locationIcon.requireData,
          anchor: const Offset(0.5, 0.5),
          onTap: () => currentPinIndexNotifier.value = -1,
          zIndex: markers.length.toDouble()));
      if (showMap.value) {
        actions.add(IconButton(
          icon: const Icon(MdiIcons.viewList),
          onPressed: () => showMap.value = false,
          tooltip: 'List View',
        ));
        content = Stack(
          children: [
            GoogleMap(
              mapType: MapType.hybrid,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              initialCameraPosition:
                  CameraPosition(target: mapState.currentLocation, zoom: 15),
              markers: markers,
              polylines: currentPinIndexNotifier.value == -1
                  ? {}
                  : {
                      Polyline(
                        polylineId: const PolylineId('CURRENT PIN LINE'),
                        points: [
                          currentCollectionNotifier
                              .pins[currentPinIndexNotifier.value].position,
                          mapState.currentLocation,
                        ],
                        visible: true,
                        color: Colors.blue,
                        width: 5,
                        patterns: [PatternItem.dot, PatternItem.gap(20)],
                      ),
                    },
              onMapCreated: mapController.setGoogleMapController,
              onTap: (_) => currentPinIndexNotifier.value = -1,
              onLongPress: addPin,
            ),
            _pinView(
              context: context,
              selectedPinIndex: currentPinIndexNotifier.value,
              selectedCollection: currentCollectionNotifier,
              currentPosition: mapState.currentLocation,
              onAddPin: addPin,
              onDeletePin: deletePin,
            ),
          ],
        );
      } else {
        actions.add(IconButton(
          icon: const Icon(MdiIcons.map),
          onPressed: () => showMap.value = true,
          tooltip: 'Map View',
        ));
        Future.delayed(
            Duration.zero, () => mapController.setGoogleMapController(null));
        content = SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...currentCollectionNotifier.pins.mapIndexed(
                (index, pin) => InkWell(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        PinView(
                          pin: pin,
                          currentPosition: mapState.currentLocation,
                        ),
                        const Spacer(),
                        if (index == currentPinIndexNotifier.value)
                          const Icon(MdiIcons.mapMarker),
                      ],
                    ),
                  ),
                  onTap: () {
                    currentPinIndexNotifier.value = index;
                    showMap.value = true;
                    mapController
                        .goTo(currentCollectionNotifier.pins[index].position);
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      }
      actions.add(IconButton(
        icon: const Icon(MdiIcons.cog),
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Settings())),
        tooltip: 'Settings',
      ));
    }
    return Scaffold(
        appBar: AppBar(
          title: Text(currentCollectionNotifier == null
              ? 'Pins'
              : currentCollectionNotifier.name),
          actions: actions,
        ),
        body: mapState.isBusy
            ? const Center(child: CircularProgressIndicator())
            : content,
        floatingActionButton: currentCollectionNotifier == null
            ? null
            : FloatingActionButton(
                onPressed: () async {
                  currentPinIndexNotifier.value = -1;
                  mapController.goToMe();
                },
                child: const Icon(MdiIcons.crosshairsGps),
              ));
  }

  Widget _pinView({
    required BuildContext context,
    required int selectedPinIndex,
    required Collection selectedCollection,
    required LatLng currentPosition,
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
          onPressed: onAddPin != null ? () => onAddPin(currentPosition) : null,
          icon: const Icon(MdiIcons.mapMarkerPlus),
          label: const Text('Add Pin Here'),
        ),
      ]);
    } else {
      Pin pin = selectedCollection.pins[selectedPinIndex];
      content = PinView(pin: pin, currentPosition: currentPosition);
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
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
}
