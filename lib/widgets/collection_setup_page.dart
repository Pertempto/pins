import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CollectionSetupPage extends HookConsumerWidget {
  final String? editCollectionId;

  bool get isEdit => editCollectionId != null;

  const CollectionSetupPage({Key? key, this.editCollectionId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreate = useState(true);
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Collection' : 'Add Collection')),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (!isEdit)
              Center(
                child: CupertinoSlidingSegmentedControl<bool>(
                  children: const {
                    true: Text('Create Collection'),
                    false: Text('Join Collection'),
                  },
                  groupValue: isCreate.value,
                  onValueChanged: (value) => isCreate.value = value!,
                ),
              ),
            if (isCreate.value) _editCollectionView(isNew: !isEdit) else _joinCollectionView()
          ],
        ),
      )),
    );
  }

  _editCollectionView({bool isNew = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(isNew ? MdiIcons.playlistPlus : MdiIcons.contentSave),
          label: Text(isNew ? 'Create Collection' : 'Save Collection'),
        ),
      ],
    );
  }

  _joinCollectionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextField(
          decoration: InputDecoration(labelText: 'Sharing Code'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(MdiIcons.playlistPlus),
          label: const Text('Join Collection'),
        ),
      ],
    );
  }
}
