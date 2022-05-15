import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/providers.dart';
import 'package:pins/widgets/collection_setup_page.dart';

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
                  ...collections.map<Widget>((collection) => _collectionView(
                        collection: collection,
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
        // TODO: show a dialog asking CREATE or JOIN.
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CollectionSetupPage())),
        tooltip: 'Add Collection',
        child: const Icon(MdiIcons.playlistPlus),
      ),
    );
  }

  _collectionView({required Collection collection, bool selected = false, bool canEdit = false}) {
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionSetupPage(editCollectionId: collection.collectionId),
                      ),
                    ),
                    icon: const Icon(MdiIcons.pencil),
                    label: const Text('Edit'),
                  ),
                // TODO: implement this
                ElevatedButton.icon(
                  onPressed: () {},
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
}
