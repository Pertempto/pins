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
  @override
  Widget build(BuildContext context) {
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
    );
  }
}
