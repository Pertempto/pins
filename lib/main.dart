import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'data/data_store.dart';

void main() {
  DataStore.init();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pins'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(position != null ? position.toString() : 'Tap the button to find your location.'),
          ],
        ),
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
      });
    }, onError: (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ERROR: $error')));
    });
  }
}
