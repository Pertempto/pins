import 'package:flutter/material.dart';

class DialogOption {
  final String label;
  final VoidCallback onPressed;

  DialogOption({required this.label, required this.onPressed});
}

class OptionsDialog extends StatelessWidget {
  final String title;
  final List<DialogOption> options;

  const OptionsDialog({Key? key, required this.title, required this.options}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return SimpleDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      children: options
          .map((e) => SimpleDialogOption(
                child: Text(e.label, style: textTheme.labelLarge),
                onPressed: () {
                  Navigator.pop(context);
                  e.onPressed();
                },
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ))
          .toList(),
    );
  }
}
