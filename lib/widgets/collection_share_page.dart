import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pins/widgets/options_dialog.dart';

import '../data/collection.dart';
import '../data/collection_request.dart';
import '../data/user.dart';
import '../providers.dart';

class CollectionSharePage extends HookConsumerWidget {
  final User currentUser;
  final String collectionId;

  const CollectionSharePage({Key? key, required this.currentUser, required this.collectionId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allUsers = ref.watch(allUsersProvider);
    final userCollectionsNotifier = ref.watch(userCollectionsProvider);
    final requests = ref.watch(collectionRequestsProvider(collectionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Share Collection')),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(12),
        child: userCollectionsNotifier.when(
          data: (collections) {
            Collection? collection;
            if (collections != null) {
              for (Collection c in collections) {
                if (c.collectionId == collectionId) {
                  collection = c;
                }
              }
            }
            if (collection == null) {
              return const Center(child: Text('Collection not found'));
            }
            return _shareCollectionView(
              context: context,
              collection: collection,
              users: allUsers.value,
              collectionRequests: requests.value,
            );
          },
          error: (e, s) => const Text('Error'),
          loading: () => const CircularProgressIndicator(),
        ),
      )),
    );
  }

  _shareCollectionView({
    required BuildContext context,
    required Collection collection,
    Map<String, User>? users,
    Iterable<CollectionRequest>? collectionRequests,
  }) {
    users ??= {};
    collectionRequests ??= [];
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(collection.name, style: textTheme.headlineSmall),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 36),
          child: Row(
            children: [
              SelectableText(collection.collectionId, style: textTheme.headlineMedium),
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
        ),
        _usersView(context: context, collection: collection, users: users),
        const SizedBox(height: 36),
        if (collectionRequests.isNotEmpty)
          _joinRequestsView(
            context: context,
            collection: collection,
            users: users,
            collectionRequests: collectionRequests,
            canAdd: collection.isModerator(currentUser.userId),
          ),
      ],
    );
  }

  _usersView({
    required BuildContext context,
    required Collection collection,
    required Map<String, User> users,
  }) {
    TextTheme textTheme = Theme.of(context).textTheme;
    bool canChangeRoles = collection.isModerator(currentUser.userId);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Users', style: textTheme.headlineSmall),
      const SizedBox(height: 4),
      ...collection.userIds.where((userId) => users[userId] != null).map((userId) {
        VoidCallback? onTap;
        if (userId != currentUser.userId && canChangeRoles) {
          onTap = () => _userDialog(context: context, collection: collection, user: users[userId]!);
        }
        IconData iconData = MdiIcons.eye;
        if (collection.isOwner(userId)) {
          iconData = MdiIcons.accountTieHat;
        } else if (collection.isModerator(userId)) {
          iconData = MdiIcons.accountCowboyHat;
        } else if (collection.isMember(userId)) {
          iconData = MdiIcons.account;
        }
        return _userItem(
          context: context,
          userId: userId,
          name: users[userId]?.name ?? userId,
          iconData: iconData,
          onTap: onTap,
        );
      }),
    ]);
  }

  _joinRequestsView({
    required BuildContext context,
    required Collection collection,
    required Map<String, User> users,
    required Iterable<CollectionRequest> collectionRequests,
    bool canAdd = false,
  }) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Join Requests', style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        ...collectionRequests
            .where((request) => users[request.userId] != null && !collection.isViewer(request.userId))
            .map((request) => _userItem(
                  context: context,
                  userId: request.userId,
                  name: users[request.userId]!.name,
                  iconData: MdiIcons.accountPlus,
                  onTap: canAdd
                      ? () => _joinDialog(
                            context: context,
                            collection: collection,
                            request: request,
                            newUser: users[request.userId]!,
                          )
                      : null,
                )),
      ],
    );
  }

  _userItem({
    required BuildContext context,
    required String userId,
    required String name,
    required IconData iconData,
    VoidCallback? onTap,
  }) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(name, style: textTheme.titleLarge),
            const Spacer(),
            Icon(iconData),
          ],
        ),
      ),
      onTap: onTap,
    );
  }

  _userDialog({required BuildContext context, required Collection collection, required User user}) {
    bool canChangeRoles = collection.isModerator(currentUser.userId);
    String role = collection.getRole(user.userId);
    showDialog(
      context: context,
      builder: (context) {
        return OptionsDialog(
          title: user.name,
          options: [
            if (canChangeRoles && [moderator, member, viewer].contains(role))
              DialogOption(
                label: 'Promote',
                onPressed: () => collection.setRole(user.userId, allRoles[allRoles.indexOf(role) - 1]),
              ),
            if (canChangeRoles && [owner, moderator, member].contains(role))
              DialogOption(
                label: 'Demote',
                onPressed: () => collection.setRole(user.userId, allRoles[allRoles.indexOf(role) + 1]),
              ),
            if (canChangeRoles)
              DialogOption(
                label: 'Remove',
                onPressed: () => collection.removeUser(user.userId),
              ),
          ],
        );
      },
    );
  }

  _joinDialog(
      {required BuildContext context,
      required Collection collection,
      required CollectionRequest request,
      required User newUser}) {
    showDialog(
      context: context,
      builder: (context) {
        return OptionsDialog(
          title: 'Join Request From ${newUser.name}',
          options: [
            DialogOption(
              label: 'Block',
              onPressed: () => request.delete(),
            ),
            DialogOption(
              label: 'Add',
              onPressed: () {
                collection.addViewer(newUser.userId);
                request.delete();
              },
            ),
          ],
        );
      },
    );
  }
}
