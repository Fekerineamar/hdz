import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A dismissable card that shows the auto-generated username & password
/// after a successful registration. The user can copy each value.
class CredentialsCard extends StatelessWidget {
  const CredentialsCard({
    super.key,
    required this.username,
    required this.password,
    required this.onDismiss,
  });

  final String username;
  final String password;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_open_rounded,
                    color: scheme.onPrimaryContainer, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تم إنشاء الحساب بنجاح ✓',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: scheme.onPrimaryContainer,
                  tooltip: 'إغلاق',
                  onPressed: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CredRow(label: 'اسم المستخدم', value: username),
            const SizedBox(height: 4),
            _CredRow(label: 'كلمة المرور', value: password),
            const SizedBox(height: 8),
            Text(
              'احتفظ بهذه البيانات في مكان آمن.',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredRow extends StatefulWidget {
  const _CredRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  State<_CredRow> createState() => _CredRowState();
}

class _CredRowState extends State<_CredRow> {
  bool _obscure = true;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPass = widget.label.contains('مرور');
    return Row(
      children: [
        Text('${widget.label}: ',
            style: TextStyle(
                fontSize: 12, color: scheme.onPrimaryContainer.withOpacity(0.8))),
        Expanded(
          child: Text(
            isPass && _obscure ? '••••••••' : widget.value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        if (isPass)
          GestureDetector(
            onTap: () => setState(() => _obscure = !_obscure),
            child: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 16,
              color: scheme.onPrimaryContainer,
            ),
          ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: widget.value));
            setState(() => _copied = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() => _copied = false);
          },
          child: Icon(
            _copied ? Icons.check : Icons.copy,
            size: 16,
            color: _copied ? Colors.green : scheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

