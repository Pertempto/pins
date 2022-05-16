import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../data/collection.dart';
import '../data/user.dart';

class CollectionSetupPage extends HookConsumerWidget {
  final User user;
  final Collection? editCollection;

  bool get isEdit => editCollection != null;

  const CollectionSetupPage({Key? key, required this.user, this.editCollection}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Collection' : 'Add Collection')),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(12),
        child: _editCollectionView(context: context, isNew: !isEdit),
      )),
    );
  }

  _editCollectionView({required BuildContext context, bool isNew = true}) {
    TextEditingController nameController = TextEditingController();
    if (isEdit) {
      nameController.text = editCollection!.name;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            String name = nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a name.'),
                ),
              );
              return;
            }
            if (isNew) {
              Collection collection = Collection.newCollection(name, user.userId);
              user.selectCollection(collection.collectionId);
            } else {
              editCollection!.name = name;
              editCollection!.saveData();
            }
            Navigator.pop(context);
          },
          icon: Icon(isNew ? MdiIcons.playlistPlus : MdiIcons.contentSave),
          label: Text(isNew ? 'Create Collection' : 'Save Collection'),
        ),
      ],
    );
  }
}
