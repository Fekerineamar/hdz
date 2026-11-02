import 'package:flutter/material.dart';

/// Simple OTP entry dialog. The incoming SMS is auto-detected by the parent;
/// this provides a manual fallback.
class SmsDialog extends StatefulWidget {
  const SmsDialog({super.key});

  @override
  State<SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<SmsDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('SMS code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the code sent to your phone '
              '(or wait for auto-detection).'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '000000',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('__RESEND__'),
          child: const Text('Resend code'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
