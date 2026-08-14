import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import '../../core/encryption/encryption_service.dart';

class PasswordFormScreen extends StatefulWidget {
  final PasswordModel? password;
  const PasswordFormScreen({super.key, this.password});
  @override
  State<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends State<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _encryptionService = EncryptionService();
  final _supabase = Supabase.instance.client;
  String _category = 'Personal';
  bool _isLoading = false;
  bool _obscure = true;

  final _categories = ['Personal', 'Social', 'Finance', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.password != null) {
      _titleController.text = widget.password!.title;
      _usernameController.text = widget.password!.username ?? '';
      _urlController.text = widget.password!.url ?? '';
      _notesController.text = widget.password!.notes ?? '';
      _category = widget.password!.category;
      _loadPassword();
    }
  }

  Future<void> _loadPassword() async {
    try {
      final decrypted = await _encryptionService.decryptData(widget.password!.passwordEncrypted);
      _passwordController.text = decrypted;
    } catch (e) {}
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    _passwordController.text = List.generate(20, (_) => chars[random.nextInt(chars.length)]).join();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final encrypted = await _encryptionService.encryptData(_passwordController.text);
      final data = {
        'user_id': userId, 'title': _titleController.text, 'username': _usernameController.text,
        'password_encrypted': encrypted, 'category': _category,
        'url': _urlController.text.isEmpty ? null : _urlController.text,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
      };
      if (widget.password != null) {
        await _supabase.from('passwords').update(data).eq('id', widget.password!.id);
      } else {
        await _supabase.from('passwords').insert(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.password != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Password' : 'New Password'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField(_titleController, 'Title', Icons.title),
            const SizedBox(height: 16),
            _buildField(_usernameController, 'Username / Email', Icons.person_outline),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController, obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.casino_outlined, size: 20), onPressed: _generatePassword, tooltip: 'Generate'),
                  IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
                ]),
                filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildField(_urlController, 'Website URL (optional)', Icons.link_outlined),
            const SizedBox(height: 16),
            _buildField(_notesController, 'Notes (optional)', Icons.notes_outlined, maxLines: 3),
            const SizedBox(height: 20),
            Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((c) {
                final selected = _category == c;
                return ChoiceChip(label: Text(c), selected: selected, onSelected: (_) => setState(() => _category = c),
                  selectedColor: theme.colorScheme.primary, backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  labelStyle: TextStyle(color: selected ? Colors.white : theme.colorScheme.onSurface, fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _isLoading ? const CircularProgressIndicator() : Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: c, maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon),
        filled: true, fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (label.contains('(optional)')) return null;
        return v == null || v.isEmpty ? 'Required' : null;
      },
    );
  }
}
