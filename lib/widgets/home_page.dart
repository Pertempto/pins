import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/data/current_position.dart';

import '../data/collection.dart';
import '../data/map_controller.dart';
import '../data/pin.dart';
import '../providers.dart';
import 'pin_view.dart';
import 'settings.dart';

class HomePage extends HookConsumerWidget {
  HomePage({Key? key}) : super(key: key);

  final _locationStreamFuture = currentPositionStream();

  final _locationIconFuture =
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(72, 72)), 'assets/icon/location.png');

  final _pinIconFuture =
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(40, 72)), 'assets/icon/pin.png');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mapController = ref.watch(mapNotifierProvider.notifier);
    final locationStream = useFuture(useMemoized(() => _locationStreamFuture), initialData: null);
    useEffect(
      () {
        if (locationStream.data != null) {
          final subscription = locationStream.data!.listen((position) {
            LatLng currentLocation = LatLng(position.latitude, position.longitude);
            mapController.setCurrentLocation(currentLocation: currentLocation);
          });
          return subscription.cancel;
        }
        return null;
      },
      [locationStream.data],
    );
    final user = ref.watch(userProvider);
    final userCollectionsNotifier = ref.watch(userCollectionsProvider);
    final currentPinIndexNotifier = useState(-1);
    final showList = useState(false);
    final locationIcon = useFuture(useMemoized(() => _locationIconFuture), initialData: BitmapDescriptor.defaultMarker);
    final pinIcon = useFuture(useMemoized(() => _pinIconFuture), initialData: BitmapDescriptor.defaultMarker);

    return userCollectionsNotifier.when(
      data: (collections) {
        bool isLoading = mapState.isLoading || collections == null;
        Collection? currentCollection;
        if (collections != null) {
          for (Collection c in collections) {
            if (c.collectionId == user.value!.currentCollectionId) {
              currentCollection = c;
            }
          }
          // If somehow the user's currentCollectionId is not found, just use the first collection.
          if (currentCollection == null && collections.isNotEmpty) {
            currentCollection = collections.first;
          }
        }
        TextTheme textTheme = Theme.of(context).textTheme;
        List<Widget> actions = [];
        Widget content;
        if (currentCollection == null) {
          content = Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You have no collections.', style: textTheme.headlineSmall),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
                  label: const Text('Setup'),
                  icon: const Icon(MdiIcons.cog),
                ),
              ],
            ),
          );
        } else {
          if (currentPinIndexNotifier.value >= currentCollection.pins.length) {
            currentPinIndexNotifier.value = -1;
          }
          if (mapState.targetLocation != null) {
            if (kDebugMode) {
              print('MOVING CAMERA TO TARGET');
            }
            mapController.moveCamera();
          }

          addPin(LatLng point) {
            if (currentCollection == null) {
              return;
            }
            currentCollection.createPin(point);
            currentPinIndexNotifier.value = currentCollection.pins.length - 1;
          }

          deletePin() {
            if (currentCollection == null) {
              return;
            }
            currentCollection.removePin(currentPinIndexNotifier.value);
            currentPinIndexNotifier.value = -1;
            mapController.goToMe();
          }

          Set<Marker> markers = currentCollection.pins
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

          actions.add(IconButton(
            icon: Icon(showList.value ? MdiIcons.map : MdiIcons.viewList),
            onPressed: () => showList.value = !showList.value,
            tooltip: showList.value ? 'Map View' : 'List View',
          ));
          content = Stack(
            children: [
              GoogleMap(
                mapType: MapType.hybrid,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(target: mapState.currentLocation, zoom: 15),
                markers: markers,
                polylines: currentPinIndexNotifier.value == -1
                    ? {}
                    : {
                        Polyline(
                          polylineId: const PolylineId('CURRENT PIN LINE'),
                          points: [
                            currentCollection.pins[currentPinIndexNotifier.value].position,
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
                onLongPress: currentCollection.isMember(user.value!.userId) ? addPin : null,
              ),
              if (showList.value)
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Material(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 16, top: 12),
                            width: double.infinity,
                            child: Text('Pins', style: textTheme.headlineSmall),
                          ),
                          ...currentCollection.pins.mapIndexed(
                            (index, pin) {
                              return InkWell(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      PinView(
                                        pin: pin,
                                        currentPosition: mapState.currentLocation,
                                      ),
                                      const Spacer(),
                                      if (index == currentPinIndexNotifier.value) const Icon(MdiIcons.mapMarker),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  currentPinIndexNotifier.value = index;
                                  showList.value = false;
                                  mapController.goTo(currentCollection!.pins[index].position);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _pinView(
                  context: context,
                  selectedPinIndex: currentPinIndexNotifier.value,
                  selectedCollection: currentCollection,
                  currentPosition: mapState.currentLocation,
                  canEdit: currentCollection.isMember(user.value!.userId),
                  onAddPin: addPin,
                  onDeletePin: deletePin,
                )
            ],
          );
        }
        actions.add(IconButton(
          icon: const Icon(MdiIcons.cog),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
          tooltip: 'Settings',
        ));
        return Scaffold(
            appBar: AppBar(
              title: Text(currentCollection == null ? 'Pins' : currentCollection.name),
              actions: actions,
            ),
            body: isLoading ? const Center(child: CircularProgressIndicator()) : content,
            floatingActionButton: currentCollection == null
                ? null
                : FloatingActionButton(
                    onPressed: () async {
                      currentPinIndexNotifier.value = -1;
                      mapController.goToMe();
                    },
                    child: const Icon(MdiIcons.crosshairsGps),
                  ));
      },
      error: (e, s) {
        if (kDebugMode) {
          print(e);
          print(s);
        }
        return Scaffold(body: Center(child: Text('ERROR: $e')));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _pinView({
    required BuildContext context,
    required int selectedPinIndex,
    required Collection selectedCollection,
    required LatLng currentPosition,
    bool canEdit = false,
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
              Text('(${currentPosition.latitude.toStringAsFixed(4)}, ${currentPosition.longitude.toStringAsFixed(4)})',
                  style: textTheme.subtitle1!),
              const Spacer(),
            ],
          ),
          if (canEdit) Text('Press and hold the map to add a pin anywhere.', style: textTheme.subtitle1!),
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
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This feature is coming soon!')));
          },
          icon: const Icon(MdiIcons.pencil),
          label: const Text('Edit'),
        ),
        // TODO: use a confirmation dialog before deleting the pin
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
                padding: EdgeInsets.fromLTRB(16, 16, 16, canEdit ? 8 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    if (canEdit) buttonBar,
                  ],
                ))));
  }
}
