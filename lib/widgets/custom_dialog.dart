import 'package:flutter/material.dart';

class DialogOption {
  final String label;
  final VoidCallback onPressed;

  DialogOption({required this.label, required this.onPressed});
}

class CustomDialog extends StatelessWidget {
  final String title;
  final String? message;
  final List<DialogOption> options;

  const CustomDialog({
    Key? key,
    required this.title,
    this.message,
    this.options = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(child: Text(title)),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(message!, style: textTheme.bodyLarge),
            )
          else
            const SizedBox(height: 8),
          ...options
              .map((e) => InkWell(
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(e.label, style: textTheme.labelLarge),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      e.onPressed();
                    },
                  ))
              .toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
