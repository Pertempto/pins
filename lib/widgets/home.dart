import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/data/collection.dart';
import 'package:pins/data/pin.dart';
import 'package:strings/strings.dart';

import '../data/data_store.dart';
import 'sign_in.dart';

class Home extends StatefulWidget {
  final bool isSignedIn;

  const Home(this.isSignedIn, {Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Completer<GoogleMapController> _controller = Completer();

  bool get _canAddPins => widget.isSignedIn && DataStore.data.currentUser!.collectionIds.isNotEmpty;
  String _selectedCollectionId = '';

  Collection? get _selectedCollection =>
      _selectedCollectionId.isNotEmpty ? DataStore.data.collections[_selectedCollectionId] : null;

  @override
  Widget build(BuildContext context) {
    double height = max(500.0, MediaQuery.of(context).size.height * 0.5);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pins'),
        actions: [
          if (widget.isSignedIn)
            IconButton(
              icon: const Icon(MdiIcons.playlistPlus),
              onPressed: () {
                _createCollectionDialog();
              },
              tooltip: 'Create Collection',
            ),
          if (widget.isSignedIn)
            IconButton(
              icon: const Icon(MdiIcons.exitRun),
              onPressed: () {
                setState(() {
                  DataStore.auth.signOut();
                });
              },
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _actionSection()),
          SizedBox(
            height: height,
            child: GoogleMap(
              mapType: MapType.hybrid,
              // initial: Dayton
              initialCameraPosition: const CameraPosition(target: LatLng(39.75, -84.20), zoom: 12),
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              markers: (_selectedCollection?.pins
                      .mapIndexed(
                        (i, p) => Marker(
                            position: p.position,
                            markerId: MarkerId(i.toString()),
                            infoWindow: InfoWindow(title: p.title, snippet: p.note)),
                      )
                      .toSet()) ??
                  <Marker>{},
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onLongPress: (point) {
                setState(() {
                  if (_canAddPins) {
                    print('ADD PIN');
                    _selectedCollection!.addPin(Pin('#${_selectedCollection!.pins.length + 1}', '', point));
                  }
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
        _updateView(LatLng(pos.latitude, pos.longitude), zoom: 18);
      });
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $error')));
    });
  }

  Future<void> _updateView(LatLng target, {double zoom = 16}) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(bearing: 0, target: LatLng(target.latitude, target.longitude), zoom: zoom)));
  }

  Widget _actionSection() {
    if (!widget.isSignedIn) {
      return Center(
        // the scroll view allows it to handle changing size gracefully
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sign in to save pins.'),
              ElevatedButton.icon(
                  icon: const Icon(MdiIcons.accountPlus), label: const Text('Sign Up'), onPressed: _signUp),
              ElevatedButton.icon(icon: const Icon(MdiIcons.account), label: const Text('Sign In'), onPressed: _signIn),
            ],
          ),
        ),
      );
    } else if (DataStore.data.currentUser!.collectionIds.isEmpty) {
      return Center(child: Text('Create a collection to start.', style: Theme.of(context).textTheme.headline6!));
    }
    if (_selectedCollectionId == '') {
      _selectedCollectionId = DataStore.data.currentUser!.collectionIds.last;
    }
    if (_selectedCollection!.pins.isEmpty) {
      return Center(child: Text('Press and hold the map to add a pin!', style: Theme.of(context).textTheme.headline6!));
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Text(_selectedCollection!.name, style: Theme.of(context).textTheme.headline5!),
                const Spacer(),
                OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This feature is not implemented yet. Check back soon!')));
                    },
                    label: const Text('Select Collection'),
                    icon: const Icon(MdiIcons.playlistStar)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _selectedCollection!.pins
                  .mapIndexed((i, p) => ListTile(
                        title: Text(p.title),
                        subtitle: Text(p.note +
                            ' (${p.position.latitude.toStringAsFixed(4)}, ${p.position.longitude.toStringAsFixed(4)})'),
                        trailing: IconButton(
                          icon: const Icon(MdiIcons.close),
                          onPressed: () {
                            setState(() {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('This feature is not implemented yet. Check back soon!')));
                            });
                          },
                        ),
                        onTap: () => _updateView(p.position),
                      ))
                  .toList(),
            ),
          ),
        ],
      );
    }
  }

  _signUp() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInWidget(isSignUp: true)));
  }

  _signIn() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInWidget(isSignUp: false)));
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
              },
            ),
          ],
        );
      },
    );
  }
}
