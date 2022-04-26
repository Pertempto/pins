import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pins/providers.dart';
import 'package:pins/widgets/sign_in.dart';

import 'firebase_options.dart';
import 'widgets/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Colors.pink[800]!;
    return MaterialApp(
      title: 'Pins',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade700,
          secondary: Colors.pink.shade700,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const Root(),
    );
  }
}

class Root extends ConsumerStatefulWidget {
  const Root({Key? key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends ConsumerState<Root> {
  bool _initialized = false;
  bool _error = false;

  // Define an async function to initialize FlutterFire
  void initializeFlutterFire() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print("ERROR: $e");
      }
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
          title: const Text("Pins"),
        ),
        body: Center(
          child: widget,
        ),
      );
    }
    final AsyncValue<auth.User?> user = ref.watch(authUserProvider);

    return user.when(
      data: (user) {
        if (user == null) {
          if (kDebugMode) {
            print('NO USER');
          }
          return const SignInWidget(isSignUp: true);
        } else {
          if (kDebugMode) {
            print('User: $user');
          }
          return HomePage();
        }
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(error.toString())),
      ),
    );
  }
}
