import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/providers.dart';
import 'package:pins/widgets/collection_setup_page.dart';

import '../data/collection.dart';
import '../data/collection_request.dart';
import '../data/user.dart';
import 'collection_share_page.dart';

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
    final userRequestsNotifier = ref.watch(userCollectionRequestsProvider(user.value?.userId ?? ''));
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
              Iterable<CollectionRequest> requests = [];
              if (userRequestsNotifier.value != null) {
                requests = userRequestsNotifier.value!;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Collections', style: textTheme.headlineSmall),
                  ...collections.map<Widget>((collection) => _collectionView(
                        collection: collection,
                        user: user.value!,
                        selected: collection.collectionId == user.value!.currentCollectionId,
                        canEdit: collection.ownerIds.contains(user.value!.userId),
                      )),
                  const SizedBox(height: 36),
                  if (requests.isNotEmpty) _joinRequests(collectionRequests: requests),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(collection.name, style: textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 8),
                    Text(collection.collectionId, style: textTheme.titleMedium),
                    const SizedBox(width: 4),
                    Icon(selected ? MdiIcons.mapMarkerMultiple : MdiIcons.chevronRight),
                  ],
                ),
              ],
            ),
            if (selected)
              ButtonBar(
                alignment: MainAxisAlignment.start,
                children: [
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CollectionSharePage(
                                    user: user,
                                    collectionId: collection.collectionId,
                                  )));
                    },
                    icon: const Icon(MdiIcons.shareVariant),
                    label: const Text('Share'),
                  ),
                ],
              )
          ],
        ),
      ),
      onTap: () {
        ref.read(userProvider).value!.selectCollection(collection.collectionId);
      },
    );
  }

  Widget _joinRequests({required Iterable<CollectionRequest> collectionRequests}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Join Requests', style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        ...collectionRequests.map((request) => _requestItem(collectionId: request.collectionId)),
      ],
    );
  }

  _requestItem({required String collectionId}) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(collectionId, style: textTheme.titleLarge),
            const Spacer(),
            const Icon(MdiIcons.playlistPlus),
          ],
        ),
      ),
      onTap: () {},
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
                _joinCollectionDialog(user: user);
              },
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Text('Join Collection', style: textTheme.labelLarge),
            ),
          ],
        );
      },
    );
  }

  _joinCollectionDialog({required User user}) {
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
                  CollectionRequest.newRequest(code, user.userId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Join request added!')));
                },
              ),
            ],
          );
        });
  }
}
