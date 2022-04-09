import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/providers.dart';

import '../data/data_store.dart';

class Settings extends ConsumerStatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<Settings> {
  late TextTheme textTheme = Theme.of(context).textTheme;

  @override
  Widget build(BuildContext context) {
    final userCollections = ref.watch(userCollectionsProvider);
    List<Widget> children = [
      Text('Collections', style: textTheme.headlineMedium),
      ...userCollections.map<Widget>((collection) => InkWell(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(collection.name + ' ' + collection.collectionId, style: textTheme.titleLarge),
                  const Spacer(),
                  const Icon(MdiIcons.chevronRight),
                ],
              ),
            ),
            onTap: () {
              DataStore.data.currentUser!.selectCollection(collection.collectionId);
              Navigator.of(context).pop();
            },
          ))
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), actions: [
        IconButton(
          onPressed: () {
            DataStore.auth.signOut().then((value) => Navigator.of(context).pop());
          },
          icon: const Icon(MdiIcons.exitRun),
          tooltip: 'Sign Out',
        ),
      ]),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
