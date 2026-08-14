import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/password_model.dart';
import '../../core/encryption/encryption_service.dart';

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
    } catch (e) { setState(() => _decryptedPassword = 'Error decrypting'); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.password;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.6), theme.colorScheme.surface,
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
                  const SizedBox(width: 48),
                ]),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
                child: Column(
                  children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                    ), child: Icon(Icons.lock_outline, color: theme.colorScheme.primary, size: 30)),
                    const SizedBox(height: 16),
                    Text(p.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(p.category, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 28),
                    _InfoTile(icon: Icons.person_outline, label: 'Username', value: p.username ?? ''),
                    const SizedBox(height: 16),
                    _InfoTile(
                      icon: Icons.lock_outline, label: 'Password',
                      value: _isPasswordVisible ? (_decryptedPassword ?? '...') : '••••••••',
                      isPassword: true, isVisible: _isPasswordVisible,
                      onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: _decryptedPassword ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied'), behavior: SnackBarBehavior.floating));
                      },
                    ),
                    if (p.url != null && p.url!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoTile(icon: Icons.link, label: 'Website', value: p.url!),
                    ],
                    if (p.notes != null && p.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InfoTile(icon: Icons.notes, label: 'Notes', value: p.notes!),
                    ],
                  ],
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
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
