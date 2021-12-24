import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:strings/strings.dart';

import '../data/collection.dart';
import '../data/data_store.dart';
import '../data/pin.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleMapController? _mapController;
  bool _positionEnabled = false;
  LatLng _position = const LatLng(39.75, -84.20);
  StreamSubscription<Position>? _positionStream;
  BitmapDescriptor locationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor pinIcon = BitmapDescriptor.defaultMarker;

  bool get _canAddPins => DataStore.data.currentUser!.collectionIds.isNotEmpty;
  String _selectedCollectionId = DataStore.data.currentUser!.collectionIds.first;
  int _selectedPinIndex = -1;

  Collection? get _selectedCollection =>
      _selectedCollectionId.isNotEmpty ? DataStore.data.collections[_selectedCollectionId] : null;

  @override
  void initState() {
    super.initState();
    _checkPosition();
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(72, 72)), 'assets/icon/location.png')
        .then((bitmap) {
      locationIcon = bitmap;
    });
    BitmapDescriptor.fromAssetImage(const ImageConfiguration(size: Size(40, 72)), 'assets/icon/pin.png').then((bitmap) {
      pinIcon = bitmap;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = (_selectedCollection?.pins
            .mapIndexed((i, p) => Marker(
                position: p.position,
                markerId: MarkerId(i.toString()),
                icon: pinIcon,
                anchor: const Offset(0, 1),
                onTap: () => setState(() => _selectedPinIndex = i),
                zIndex: i.toDouble()))
            .toSet()) ??
        <Marker>{};
    markers.add(Marker(
        position: _position,
        markerId: const MarkerId('position'),
        icon: locationIcon,
        anchor: const Offset(0.5, 0.5),
        onTap: () => setState(() => _selectedPinIndex = -1),
        zIndex: markers.length.toDouble()));
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCollection!.name),
        actions: [
          // TODO: add collection screen
          // IconButton(
          //   icon: const Icon(MdiIcons.playlistEdit),
          //   onPressed: () {},
          //   tooltip: 'View Collection',
          // ),
          IconButton(
            icon: const Icon(MdiIcons.cog),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(target: _position),
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (GoogleMapController controller) => setState(() => _mapController = controller),
            onLongPress: _addPin,
          ),
          _pinView(),
        ],
      ),
      floatingActionButton: _mapController == null || !_positionEnabled
          ? null
          : FloatingActionButton(
              onPressed: _locate,
              tooltip: 'Find Me',
              child: const Icon(MdiIcons.crosshairsGps),
              heroTag: null,
            ),
      resizeToAvoidBottomInset: true,
    );
  }

  _checkPosition() {
    DataStore.determinePosition().then((pos) {
      _positionStream = Geolocator.getPositionStream(distanceFilter: 2).listen((Position position) {
        setState(() {
          print(position);
          _position = LatLng(position.latitude, position.longitude);
        });
      });
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
        _positionEnabled = true;
        _updateView(_position, zoom: 18);
      });
    }, onError: (error) {
      setState(() {
        _positionEnabled = false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $error')));
      });
    });
  }

  _locate() {
    setState(() {
      _selectedPinIndex = -1;
      _updateView(_position);
    });
  }

  Future<void> _updateView(LatLng target, {double? zoom}) async {
    CameraPosition cameraPosition;
    if (zoom != null) {
      cameraPosition = CameraPosition(bearing: 0, target: target, zoom: zoom);
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    } else {
      cameraPosition = CameraPosition(bearing: 0, target: LatLng(target.latitude, target.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    }
  }

  _addPin(LatLng point) {
    setState(() {
      if (_canAddPins) {
        _selectedCollection!.createPin(point);
        _selectedPinIndex = _selectedCollection!.pins.length - 1;
      }
    });
  }

  _createCollectionDialog() {
    TextEditingController textFieldController = TextEditingController(text: 'My Pins');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Collection'),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Name:'),
              ),
              Expanded(
                child: TextField(
                  autofocus: true,
                  controller: textFieldController,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                if (textFieldController.value.text.trim().isEmpty) {
                  return;
                }
                String name = textFieldController.value.text.split(RegExp(r'\s+')).map((w) => capitalize(w)).join(' ');
                Navigator.pop(context);
                String collectionId = Collection.generateId();
                DataStore.data.currentUser!.addCollection(collectionId);
                Collection.newCollection(collectionId, name, DataStore.data.currentUser!.userId);
                setState(() {
                  _selectedCollectionId = collectionId;
                });
              },
            ),
          ],
        );
      },
    );
  }

  _selectCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Collection'),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: DataStore.data.collections.values
                .where((collection) => collection.userIds.contains(DataStore.data.currentUser!.userId))
                .map<Widget>((collection) => GestureDetector(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(collection.name, style: Theme.of(context).textTheme.headline6),
                              const Spacer(),
                              const Icon(MdiIcons.playlistPlay),
                            ],
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedCollectionId = collection.collectionId);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        );
      },
    );
  }

  Widget _pinView() {
    TextTheme textTheme = Theme.of(context).textTheme;
    String title, note, subText;
    Widget buttonBar;
    if (_selectedPinIndex == -1) {
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
      Pin pin = _selectedCollection!.pins[_selectedPinIndex];
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
            setState(() {
              _selectedCollection!.removePin(_selectedPinIndex);
              _selectedPinIndex = -1;
            });
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
