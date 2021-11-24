import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';
import 'sign_in.dart';

class Home extends StatefulWidget {
  final bool isSignedIn;

  const Home(this.isSignedIn, {Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<LatLng> pins = [];
  final Completer<GoogleMapController> _controller = Completer();

  bool get _canAddPins => widget.isSignedIn && DataStore.data.currentUser!.collectionIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    double height = max(500.0, MediaQuery.of(context).size.height * 0.6);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pins'),
        actions: [
          if (widget.isSignedIn)
            IconButton(
              icon: const Icon(MdiIcons.playlistPlus),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This feature is not implemented yet. Check back soon!')));
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
              markers: pins
                  .mapIndexed(
                    (i, p) => Marker(
                        position: p, markerId: MarkerId(i.toString()), infoWindow: InfoWindow(title: '#${i + 1}')),
                  )
                  .toSet(),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onLongPress: (point) {
                setState(() {
                  if (_canAddPins) {
                    pins.add(point);
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
    } else if (pins.isEmpty) {
      return Center(child: Text('Press and hold the map to add a pin!', style: Theme.of(context).textTheme.headline6!));
    } else {
      return ListView(
        children: pins
            .mapIndexed((i, p) => ListTile(
                  title: Text('#${i + 1} (${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})'),
                  trailing: IconButton(
                    icon: const Icon(MdiIcons.close),
                    onPressed: () {
                      setState(() {
                        pins.remove(p);
                      });
                    },
                  ),
                  onTap: () => _updateView(p),
                  dense: true,
                ))
            .toList(),
      );
    }
  }

  _signUp() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInWidget(isSignUp: true)));
  }

  _signIn() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInWidget(isSignUp: false)));
  }
}
