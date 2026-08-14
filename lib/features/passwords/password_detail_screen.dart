import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'password_form_screen.dart';

class PasswordDetailScreen extends StatefulWidget {
  final PasswordModel password;
  const PasswordDetailScreen({super.key, required this.password});
  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  final EncryptionService _encryptionService = EncryptionService();
  String? _decryptedPassword;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _decryptPassword();
  }

  Future<void> _decryptPassword() async {
    try {
      final decrypted = await _encryptionService.decryptData(widget.password.passwordEncrypted);
      setState(() => _decryptedPassword = decrypted);
    } catch (e) {
      debugPrint('Decryption error: $e');
      setState(() => _decryptedPassword = null);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
            title: const Text('Decryption Failed'),
            content: const Text('Could not decrypt this password. The encryption key may have been changed or lost. You can delete this entry and create a new one.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await Supabase.instance.client.from('passwords').delete().eq('id', widget.password.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Delete Entry', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.password;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6), theme.colorScheme.surface,
        ])),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white)),
                  const Spacer(),
                  Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordFormScreen(password: p))).then((_) => Navigator.pop(context)),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Password'),
                          content: Text('Delete "${p.title}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await Supabase.instance.client.from('passwords').delete().eq('id', p.id);
                  if (mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    tooltip: 'Delete',
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22)),
                        child: Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 32),
                      )),
                      const SizedBox(height: 20),
                      Center(child: Text(p.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(p.category, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                      )),
                      const SizedBox(height: 28),
                      _InfoTile(
                        icon: Icons.person_outline, label: 'Username', value: p.username ?? '',
                        onCopy: () => _copyToClipboard(p.username ?? '', 'Username'),
                      ),
                      const SizedBox(height: 14),
                      _InfoTile(
                        icon: Icons.lock_outline, label: 'Password',
                        value: _isPasswordVisible ? (_decryptedPassword ?? '...') : '••••••••',
                        isPassword: true, isVisible: _isPasswordVisible,
                        onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        onCopy: () => _copyToClipboard(_decryptedPassword ?? '', 'Password'),
                      ),
                      if (p.url != null && p.url!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _InfoTile(
                          icon: Icons.link, label: 'Website', value: p.url!,
                          onCopy: () => _copyToClipboard(p.url!, 'URL'),
                        ),
                      ],
                      if (p.notes != null && p.notes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _InfoTile(icon: Icons.notes, label: 'Notes', value: p.notes!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggle;
  final VoidCallback? onCopy;

  const _InfoTile({required this.icon, required this.label, required this.value, this.isPassword = false, this.isVisible = false, this.onToggle, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: isPassword && !isVisible ? 2 : 0.5), maxLines: 3)),
          if (isPassword) IconButton(onPressed: onToggle, icon: Icon(isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20)),
          if (onCopy != null) IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_outlined, size: 20)),
        ]),
      ]),
    );
  }
}
