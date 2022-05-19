import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/data/current_position.dart';

import '../data/collection.dart';
import '../data/map_controller.dart';
import '../data/pin.dart';
import '../providers.dart';
import 'custom_app_bar.dart';
import 'pin_view.dart';
import 'settings.dart';

// From https://stackoverflow.com/a/56534916, so that marker icons appear correctly on iOS.
Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

class HomePage extends HookConsumerWidget {
  HomePage({Key? key}) : super(key: key);

  final _locationStreamFuture = currentPositionStream();

  final _locationIconFuture = getBytesFromAsset('assets/icon/location.png', 108);

  final _pinIconFuture = getBytesFromAsset('assets/icon/pin.png', 60);

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
    final locationIcon = useFuture(useMemoized(() {
      return _locationIconFuture;
    }));
    final pinIcon = useFuture(useMemoized(() {
      print('PLATFORM IS IOS ${defaultTargetPlatform == TargetPlatform.iOS}');
      return _pinIconFuture;
    }));

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
        ColorScheme colorScheme = Theme.of(context).colorScheme;
        List<Widget> actions = [];
        Widget background =
            Container(width: double.infinity, height: double.infinity, color: colorScheme.surfaceVariant);
        Widget content = Container();
        Widget appBarBottom = Container();
        if (currentCollection == null) {
          content = Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('You have no collections.', style: textTheme.headlineSmall),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
                label: const Text('Setup'),
                icon: const Icon(MdiIcons.cog),
              ),
            ],
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
                    icon: pinIcon.data == null
                        ? BitmapDescriptor.defaultMarker
                        : BitmapDescriptor.fromBytes(pinIcon.data!),
                  ))
              .toSet();
          markers.add(Marker(
              position: mapState.currentLocation,
              markerId: const MarkerId('position'),
              icon: locationIcon.data == null
                  ? BitmapDescriptor.defaultMarker
                  : BitmapDescriptor.fromBytes(locationIcon.data!),
              anchor: const Offset(0.5, 0.5),
              onTap: () => currentPinIndexNotifier.value = -1,
              zIndex: markers.length.toDouble()));

          actions.add(IconButton(
            icon: Icon(showList.value ? MdiIcons.map : MdiIcons.viewList),
            onPressed: () => showList.value = !showList.value,
            tooltip: showList.value ? 'Map View' : 'List View',
          ));
          background = GoogleMap(
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
          );
          if (showList.value) {
            appBarBottom = Container(
              height: 300,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: currentCollection.pins.mapIndexed(
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
                    ).toList(),
                  ),
                ),
              ),
            );
          } else {
            appBarBottom = _pinView(
              context: context,
              selectedPinIndex: currentPinIndexNotifier.value,
              selectedCollection: currentCollection,
              currentPosition: mapState.currentLocation,
              canEdit: currentCollection.isMember(user.value!.userId),
              onAddPin: addPin,
              onDeletePin: deletePin,
            );
          }
        }
        actions.add(IconButton(
          icon: const Icon(MdiIcons.cog),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
          tooltip: 'Settings',
        ));
        return Scaffold(
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      background,
                      SafeArea(
                        child: Column(
                          children: [
                            CustomAppBar(
                              title: currentCollection?.name ?? 'Pins',
                              actions: actions,
                              bottom: appBarBottom,
                            ),
                            Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: content),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;
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
        child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, canEdit ? 8 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (canEdit) buttonBar,
              ],
            )));
  }
}
