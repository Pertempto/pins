import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/location_controller.dart';
import '../data/pin.dart';
import '../providers.dart';

class Home extends HookConsumerWidget {
  const Home({Key? key}) : super(key: key);


@override
Widget build(BuildContext context, WidgetRef ref) {
  final Completer<GoogleMapController> completer = Completer();
  final collections = ref.watch(userCollectionsProvider);
  // final position = ref.watch(geolocatorContStaNotiPro);
  final locationIcon = useFuture(
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(72, 72)), 'assets/icon/location.png'),
      initialData: BitmapDescriptor.defaultMarker);
  final pinIcon = useFuture(
      BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(40, 72)), 'assets/icon/pin.png'),
      initialData: BitmapDescriptor.defaultMarker);
  final mapController = useFuture(completer.future);
  int selectedPinIndex = -1;

  var selectedCollection = collections.first;
  // Set<Marker> markers = (selectedCollection.pins
  //         .mapIndexed((i, p) => Marker(
  //             position: p.position,
  //             markerId: MarkerId(i.toString()),
  //             icon: pinIcon.requireData,
  //             anchor: const Offset(0, 1),
  //             // onTap: () => setState(() => _selectedPinIndex = i),
  //             zIndex: i.toDouble()))
  //         .toSet()) ??
  //     <Marker>{};
  // markers.add(Marker(
  //     position: position.value!,
  //     markerId: const MarkerId('position'),
  //     icon: locationIcon.requireData,
  //     anchor: const Offset(0.5, 0.5),
  //     // onTap: () => setState(() => _selectedPinIndex = -1),
  //     zIndex: markers.length.toDouble()));
  return Scaffold(

    body: Stack(
      children: [
        // GoogleMap(
        //   mapType: MapType.hybrid,
        //   // initialCameraPosition: CameraPosition(target: position.value!),
        //   mapToolbarEnabled: false,
        //   zoomControlsEnabled: false,
        //   // markers: markers,
        //   onMapCreated: (GoogleMapController controller) => completer.complete(controller),
        //   onLongPress: _addPin,
        // ),
        // // _pinView(context, selectedPinIndex, selectedCollection, position.value!),
      ],
    ),
    floatingActionButton: !mapController.hasData
        ? null
        : FloatingActionButton(
            onPressed: () {
              selectedPinIndex = -1;
              // _updateView(completer, position.value!);
            },
            tooltip: 'Find Me',
            child: const Icon(MdiIcons.crosshairsGps),
            heroTag: null,
          ),
    resizeToAvoidBottomInset: true,
  );
}

  _locate() {
    // setState(() {
    //   _selectedPinIndex = -1;
    //   _updateView(_position);
    // });
  }

  Future<void> _updateView(Completer<GoogleMapController> completer, LatLng target, {double? zoom}) async {
    print('UPDATE VIEW');
    CameraPosition cameraPosition;
    final GoogleMapController controller = await completer.future;
    if (zoom != null) {
      cameraPosition = CameraPosition(bearing: 0, target: target, zoom: zoom);
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    } else {
      cameraPosition = CameraPosition(bearing: 0, target: LatLng(target.latitude, target.longitude));
      controller.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  _addPin(LatLng point) {
    // setState(() {
    //   if (_canAddPins) {
    //     _selectedCollection!.createPin(point);
    //     _selectedPinIndex = _selectedCollection!.pins.length - 1;
    //   }
    // });
  }

//
// _createCollectionDialog() {
//   TextEditingController textFieldController = TextEditingController(text: 'My Pins');
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text('Create Collection'),
//         contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
//         content: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: <Widget>[
//             const Padding(
//               padding: EdgeInsets.only(right: 12),
//               child: Text('Name:'),
//             ),
//             Expanded(
//               child: TextField(
//                 autofocus: true,
//                 controller: textFieldController,
//               ),
//             ),
//           ],
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           TextButton(
//             child: const Text('Submit'),
//             onPressed: () {
//               if (textFieldController.value.text.trim().isEmpty) {
//                 return;
//               }
//               String name = textFieldController.value.text.split(RegExp(r'\s+')).map((w) => capitalize(w)).join(' ');
//               Navigator.pop(context);
//               String collectionId = Collection.generateId();
//               DataStore.data.currentUser!.addCollection(collectionId);
//               Collection.newCollection(collectionId, name, DataStore.data.currentUser!.userId);
//               setState(() {});
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

  Widget _pinView(BuildContext context, int selectedPinIndex, Collection selectedCollection, LatLng _position) {
    TextTheme textTheme = Theme.of(context).textTheme;
    String title, note, subText;
    Widget buttonBar;
    if (selectedPinIndex == -1) {
      title = 'Here';
      note = '(${_position.latitude.toStringAsFixed(4)}, ${_position.longitude.toStringAsFixed(4)})';
      subText = 'Press and hold the map to add a pin.';
      buttonBar = ButtonBar(alignment: MainAxisAlignment.start, children: [
        // TODO: make this work
        // OutlinedButton.icon(
        //   onPressed: () {},
        //   icon: const Icon(MdiIcons.formatListBulleted),
        //   label: const Text('Select Pin'),
        // ),
        OutlinedButton.icon(
          onPressed: () => _addPin(_position),
          icon: const Icon(MdiIcons.mapMarkerPlus),
          label: const Text('Add Pin Here'),
        ),
      ]);
    } else {
      Pin pin = selectedCollection.pins[selectedPinIndex];
      title = pin.title;
      note = pin.note;
      double distanceMeters = Geolocator.distanceBetween(
          _position.latitude, _position.longitude, pin.position.latitude, pin.position.longitude);
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
          onPressed: () {
            selectedCollection.removePin(selectedPinIndex);
          },
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
