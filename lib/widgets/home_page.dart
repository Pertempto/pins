import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/location_controller.dart';
import '../providers.dart';
import 'settings.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(mapNotifierProvider);
    final mapNotifier = ref.watch(mapNotifierProvider.notifier);
    final currentCollectionNotifier = ref.watch(userCurrentCollectionProvider);

    useEffect(() {
      Future.microtask(() async => ref.watch(mapNotifierProvider.notifier).getCurrentLocation());
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
        body: mapState.isBusy
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                mapType: MapType.hybrid,
                mapToolbarEnabled: false,
                myLocationButtonEnabled: false,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(target: mapState.currentLocation, zoom: 15),
                markers: currentCollectionNotifier?.pins
                        .mapIndexed((i, p) => Marker(
                            position: p.position,
                            markerId: MarkerId(i.toString()),
                            anchor: const Offset(0, 1),
                            // onTap: () => setState(() => _selectedPinIndex = i),
                            zIndex: i.toDouble()))
                        .toSet() ??
                    {},
                onMapCreated: mapNotifier.onMapCreated,
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async => mapNotifier.goToMe(),
          child: const Icon(MdiIcons.crosshairsGps),
        ));
  }
}
