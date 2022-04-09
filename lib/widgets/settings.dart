import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/data_store.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late TextTheme textTheme = Theme.of(context).textTheme;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Text('Collections', style: textTheme.headlineMedium),
      ...DataStore.data.currentUser!.collectionIds
          .map((id) => DataStore.data.collections[id])
          .where((collection) => collection != null && collection.userIds.contains(DataStore.data.currentUser!.userId))
          .map<Widget>(
            (collection) => InkWell(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(collection!.name + ' ' + collection.collectionId, style: textTheme.titleLarge),
                    const Spacer(),
                    const Icon(MdiIcons.chevronRight),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  DataStore.data.currentUser!.selectCollection(collection.collectionId);
                });
                Navigator.of(context).pop();
              },
            ),
          ),
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
