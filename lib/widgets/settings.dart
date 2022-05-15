import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/providers.dart';

import '../data/collection.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  late TextTheme textTheme = Theme.of(context).textTheme;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userCollectionsNotifier = ref.watch(userCollectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), actions: [
        IconButton(
          onPressed: () => FirebaseAuth.instance.signOut().then((value) => Navigator.of(context).pop()),
          icon: const Icon(MdiIcons.exitRun),
          tooltip: 'Sign Out',
        ),
      ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: userCollectionsNotifier.when(
            data: (collections) {
              if (collections == null) {
                return const Center(child: Text('No Collections'));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collections', style: textTheme.headlineMedium),
                  ...collections.map<Widget>((collection) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(collection.name, style: textTheme.titleLarge),
                              const Spacer(),
                              Text(collection.collectionId, style: textTheme.titleMedium),
                              const Icon(MdiIcons.chevronRight),
                            ],
                          ),
                        ),
                        onTap: () {
                          ref.read(userProvider).value!.selectCollection(collection.collectionId);
                          Navigator.of(context).pop();
                        },
                      )),
                  ElevatedButton.icon(
                    onPressed: () {
                      Collection collection = Collection.newCollection('TEST!', user.value!.userId);
                      user.value!.selectCollection(collection.collectionId);
                    },
                    label: const Text('Create Collection'),
                    icon: const Icon(MdiIcons.playlistPlus),
                  ),
                ],
              );
            },
            error: (e, s) => const Text('Error'),
            loading: () => const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
