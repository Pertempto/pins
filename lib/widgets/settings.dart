import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/providers.dart';
import 'package:pins/widgets/collection_setup_page.dart';

import '../data/collection.dart';
import '../data/user.dart';

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
          onPressed: () => auth.FirebaseAuth.instance.signOut().then((value) => Navigator.of(context).pop()),
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
                  ...collections.map<Widget>((collection) => _collectionView(
                        collection: collection,
                        user: user.value!,
                        selected: collection.collectionId == user.value!.currentCollectionId,
                        canEdit: collection.ownerIds.contains(user.value!.userId),
                      )),
                ],
              );
            },
            error: (e, s) => const Text('Error'),
            loading: () => const CircularProgressIndicator(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCollectionDialog(user: user.value!),
        tooltip: 'Add Collection',
        child: const Icon(MdiIcons.playlistPlus),
      ),
    );
  }

  _collectionView({required Collection collection, required User user, bool selected = false, bool canEdit = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Text(collection.name, style: textTheme.titleLarge),
                const Spacer(),
                Text(collection.collectionId, style: textTheme.titleMedium),
                const SizedBox(width: 4),
                Icon(selected ? MdiIcons.mapMarkerMultiple : MdiIcons.chevronRight),
              ],
            ),
            if (selected)
              ButtonBar(alignment: MainAxisAlignment.start, children: [
                if (canEdit)
                  OutlinedButton.icon(
                    onPressed: () {
                      var route = MaterialPageRoute(
                        builder: (context) => CollectionSetupPage(user: user, editCollection: collection),
                      );
                      Navigator.push(context, route);
                    },
                    icon: const Icon(MdiIcons.pencil),
                    label: const Text('Edit'),
                  ),
                // TODO: implement sharing
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('This feature is coming soon!')));
                  },
                  icon: const Icon(MdiIcons.shareVariant),
                  label: const Text('Share'),
                ),
              ])
          ],
        ),
      ),
      onTap: () {
        ref.read(userProvider).value!.selectCollection(collection.collectionId);
      },
    );
  }

  _addCollectionDialog({required User user}) {
    TextTheme textTheme = Theme.of(context).textTheme;
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Add Collection'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => CollectionSetupPage(user: user)));
              },
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Text('Create Collection', style: textTheme.labelLarge),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _joinCollectionDialog();
              },
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Text('Join Collection', style: textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }

  _joinCollectionDialog() {
    TextEditingController textFieldController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Join Collection'),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            content: TextField(
              autofocus: true,
              controller: textFieldController,
              decoration: const InputDecoration(labelText: 'Sharing Code'),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Submit'),
                onPressed: () {
                  String code = textFieldController.value.text.trim();
                  if (code.isEmpty) {
                    return;
                  }
                  Navigator.pop(context);
                  // TODO: do something with the code.
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Code: "$code". This feature is coming soon!')));
                },
              ),
            ],
          );
        });
  }
}
