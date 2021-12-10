import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'data/data_store.dart';
import 'widgets/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Pins',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.green[700]!,
          primaryVariant: Colors.green[800]!,
          secondary: Colors.brown[700]!,
          secondaryVariant: Colors.brown[800]!,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({Key? key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp();
      await DataStore.init();
      setState(() {
        print("INIT DONE");
        _initialized = true;
      });
    } catch (e) {
      print("ERROR: $e");
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  @override
  void initState() {
    initializeFlutterFire();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget? widget;
    if (_error) {
      widget = const Text("Error!");
    } else if (!_initialized) {
      widget = const CircularProgressIndicator();
    }
    if (widget != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Verse Typer"),
        ),
        body: Center(
          child: widget,
        ),
      );
    }
    return DataStore.dataWrap(() {
      print('MAIN UPDATE');
      if (DataStore.isLoading) {
        return Scaffold(
          appBar: AppBar(title: const Text("Loading...")),
          body: const Center(child: CircularProgressIndicator()),
        );
      } else {
        return Home(DataStore.data.isSignedIn);
      }
    });
  }
}
