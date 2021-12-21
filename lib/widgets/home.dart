import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:strings/strings.dart';

import '../data/collection.dart';
import '../data/data_store.dart';
import '../data/pin.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  GoogleMapController? _mapController;
  LatLng? _position;

  bool get _canAddPins => DataStore.data.currentUser!.collectionIds.isNotEmpty;
  String _selectedCollectionId = DataStore.data.currentUser!.collectionIds.first;
  Pin? _selectedPin;

  Collection? get _selectedCollection =>
      _selectedCollectionId.isNotEmpty ? DataStore.data.collections[_selectedCollectionId] : null;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(DataStore.data.currentUser!.collectionIds);
    print('collection id: $_selectedCollectionId');
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCollection!.name),
        actions: [
          IconButton(
            icon: const Icon(MdiIcons.playlistEdit),
            onPressed: () {},
            tooltip: 'View Collection',
          ),
          IconButton(
            icon: const Icon(MdiIcons.cog),
            onPressed: () {},
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            // initial: Dayton
            initialCameraPosition: const CameraPosition(target: LatLng(39.75, -84.20), zoom: 12),
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            circles: _position == null
                ? {}
                : {
                    Circle(
                        circleId: const CircleId('position'),
                        center: _position!,
                        radius: 5,
                        strokeWidth: 3,
                        strokeColor: Colors.red)
                  },
            markers: (_selectedCollection?.pins
                    .mapIndexed(
                      (i, p) => Marker(
                        position: p.position,
                        markerId: MarkerId(i.toString()),
                        onTap: () {
                          setState(() {
                            _selectedPin = p;
                          });
                        },
                      ),
                    )
                    .toSet()) ??
                <Marker>{},
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                _mapController = controller;
              });
            },
            onLongPress: (point) {
              setState(() {
                if (_canAddPins) {
                  _selectedCollection!.createPin(point);
                }
              });
            },
          ),
          _pinView(),
        ],
      ),
      floatingActionButton: _mapController == null
          ? null
          : FloatingActionButton(
              onPressed: _locate,
              tooltip: 'Find Me',
              child: const Icon(MdiIcons.crosshairsGps),
            ),
      resizeToAvoidBottomInset: true,
    );
  }

  _locate() {
    DataStore.determinePosition().then((pos) {
      setState(() {
        _position = LatLng(pos.latitude, pos.longitude);
        _updateView(_position!, zoom: 18);
      });
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $error')));
    });
  }

  Future<void> _updateView(LatLng target, {double zoom = 16}) async {
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(bearing: 0, target: LatLng(target.latitude, target.longitude), zoom: zoom)));
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
    Widget content;
    if (_selectedPin == null) {
      content = Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Press and hold the map to add a pin!', style: textTheme.headline6!),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_selectedPin!.title, style: textTheme.headline6!),
                const SizedBox(width: 16),
                Text(_selectedPin!.note, style: textTheme.subtitle1!),
                const Spacer(),
              ],
            ),
            ButtonBar(alignment: MainAxisAlignment.start, children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(MdiIcons.formatListBulleted),
                label: const Text('Select'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(MdiIcons.pencil),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(MdiIcons.delete),
                label: const Text('Delete'),
              ),
            ])
          ],
        ),
      );
    }
    return SizedBox(width: double.infinity, child: Card(margin: const EdgeInsets.all(16), child: content));
  }
}
