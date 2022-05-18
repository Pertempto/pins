import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String? title;
  final List<Widget> actions;
  final Widget? bottom;

  const CustomAppBar({
    Key? key,
    this.title,
    this.actions = const [],
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: colorScheme.background,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Container(
                // margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // borderRadius: const BorderRadius.all(Radius.circular(24)),
                  color: colorScheme.surfaceVariant,
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Text(
                        title ?? '',
                        style: textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    ...actions,
                  ],
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
