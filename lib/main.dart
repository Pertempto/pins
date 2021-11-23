import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'data/data_store.dart';

void main() {
  DataStore.init();
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.green[700]!,
          primaryVariant: Colors.green[800]!,
          secondary: Colors.brown[700]!,
          secondaryVariant: Colors.brown[800]!,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Position? position;
  List<LatLng> pins = [];
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    double height = max(500.0, MediaQuery.of(context).size.height * 0.6);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pins'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: height,
            child: GoogleMap(
              mapType: MapType.hybrid,
              // initial: Dayton
              initialCameraPosition: const CameraPosition(target: LatLng(39.75, -84.20), zoom: 12),
              zoomControlsEnabled: false,
              markers: pins.mapIndexed((i, p) => Marker(position: p, markerId: MarkerId(i.toString()))).toSet(),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onLongPress: (point) {
                setState(() {
                  pins.add(point);
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: pins
                  .map((p) => ListTile(
                        title: Text('(${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)})'),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _locate,
        tooltip: 'Pin',
        child: const Icon(MdiIcons.mapMarker),
      ),
    );
  }

  _locate() {
    DataStore.determinePosition().then((pos) {
      setState(() {
        position = pos;
        _updateView();
      });
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $error')));
    });
  }

  Future<void> _updateView() async {
    if (position != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(bearing: 0, target: LatLng(position!.latitude, position!.longitude), zoom: 19)));
    }
  }
}
