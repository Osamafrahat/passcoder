import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});
  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  int _passwordLength = 16;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;
  String _generatedPassword = '';
  double _strength = 0;
  String _strengthLabel = '';

  @override
  void initState() { super.initState(); _generatePassword(); }

  void _generatePassword() {
    String chars = 'abcdefghijklmnopqrstuvwxyz';
    if (_includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_includeNumbers) chars += '0123456789';
    if (_includeSpecialChars) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    if (chars.isEmpty) chars = 'abcdefghijklmnopqrstuvwxyz';

    final random = Random.secure();
    _generatedPassword = List.generate(_passwordLength, (_) => chars[random.nextInt(chars.length)]).join();
    _calculateStrength();
    setState(() {});
  }

  void _calculateStrength() {
    int score = 0;
    if (_generatedPassword.length >= 8) score++;
    if (_generatedPassword.length >= 14) score++;
    if (RegExp(r'[A-Z]').hasMatch(_generatedPassword)) score++;
    if (RegExp(r'[0-9]').hasMatch(_generatedPassword)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_generatedPassword)) score++;

    _strength = score / 5;
    if (_strength < 0.4) _strengthLabel = 'Weak';
    else if (_strength < 0.7) _strengthLabel = 'Medium';
    else _strengthLabel = 'Strong';
  }

  Color _strengthColor() {
    if (_strength < 0.4) return Colors.red;
    if (_strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Password Generator', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: [
            SelectableText(_generatedPassword, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _actionBtn(Icons.copy_outlined, 'Copy', () {
                Clipboard.setData(ClipboardData(text: _generatedPassword));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), behavior: SnackBarBehavior.floating));
              }),
              const SizedBox(width: 12),
              _actionBtn(Icons.refresh, 'Regenerate', _generatePassword),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Length: $_passwordLength', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$_passwordLength chars', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
            ]),
            Slider(
              value: _passwordLength.toDouble(), min: 6, max: 64,
              onChanged: (v) { _passwordLength = v.round(); _generatePassword(); },
              activeColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Strength', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              Text(_strengthLabel, style: TextStyle(color: _strengthColor(), fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: _strength, backgroundColor: theme.colorScheme.surfaceContainerHighest, color: _strengthColor(), minHeight: 6),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            _toggleTile('Uppercase Letters', 'A-Z', _includeUppercase, (v) => setState(() { _includeUppercase = v; _generatePassword(); })),
            const Divider(),
            _toggleTile('Numbers', '0-9', _includeNumbers, (v) => setState(() { _includeNumbers = v; _generatePassword(); })),
            const Divider(),
            _toggleTile('Special Characters', '!@#\$%', _includeSpecialChars, (v) => setState(() { _includeSpecialChars = v; _generatePassword(); })),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _toggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ]),
      Switch(value: value, onChanged: onChanged),
    ]);
  }
}
