import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/user.dart';

class CollectionSharePage extends HookConsumerWidget {
  final User user;
  final Collection collection;

  const CollectionSharePage({Key? key, required this.user, required this.collection}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Sharing')),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(12),
        child: _shareCollectionView(context: context),
      )),
    );
  }

  _shareCollectionView({required BuildContext context}) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(collection.name, style: textTheme.headlineSmall),
            const Spacer(),
            Text(collection.collectionId, style: textTheme.headlineMedium),
          ],
        ),
        Row(
          children: [
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: collection.collectionId)).then((_) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Sharing code copied to clipboard!')));
                });
              },
              icon: const Icon(MdiIcons.contentCopy),
              label: const Text('Copy Sharing Code'),
            ),
          ],
        ),
        Text('Users', style: textTheme.titleLarge),
        ...collection.viewerIds.map((userId) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // TODO: show user name instead of ID
                  Text(userId, style: textTheme.titleMedium),
                  const Spacer(),
                  Icon(collection.ownerIds.contains(userId) ? MdiIcons.accountCowboyHat : MdiIcons.account),
                ],
              ),
            )),
      ],
    );
  }
}
