import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/location_controller.dart';
import 'settings.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);
    final locationNotifier = ref.watch(locationNotifierProvider.notifier);

    useEffect(() {
      Future.microtask(() async {
        ref.watch(locationNotifierProvider.notifier).getCurrentLocation();
      });
      return;
    }, const []);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Pins'),
          actions: [
            // TODO: add collection screen
            IconButton(
              icon: const Icon(MdiIcons.playlistEdit),
              onPressed: () {},
              tooltip: 'View Collection',
            ),
            IconButton(
              icon: const Icon(MdiIcons.cog),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Settings())),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: locationState.isBusy
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                mapType: MapType.hybrid,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(target: locationState.currentLocation, zoom: 15),
                markers: locationState.markers,
                onMapCreated: locationNotifier.onMapCreated,
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async => locationNotifier.goToMe(),
          child: const Icon(MdiIcons.crosshairsGps),
        ));
  }
}
