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

  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryptionService = EncryptionService();

  String _selectedCategory = 'General';
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _categories = [
    'General',
    'Social',
    'Email',
    'Banking',
    'Shopping',
    'Work',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.password != null) {
      _titleController.text = widget.password!.title;
      _usernameController.text = widget.password!.username ?? '';
      _urlController.text = widget.password!.url ?? '';
      _notesController.text = widget.password!.notes ?? '';
      _selectedCategory = widget.password!.category;
      _isFavorite = widget.password!.isFavorite;
      _decryptExistingPassword();
    }
  }

  Future<void> _decryptExistingPassword() async {
    if (widget.password != null) {
      try {
        final decrypted = await _encryptionService.decryptData(widget.password!.passwordEncrypted);
        setState(() => _passwordController.text = decrypted);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error decrypting password: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final Random random = Random();
    final StringBuffer password = StringBuffer();

    for (int i = 0; i < 16; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }

    setState(() => _passwordController.text = password.toString());
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final encryptedPassword = await _encryptionService.encryptData(_passwordController.text);

      final passwordData = {
        'user_id': userId,
        'title': _titleController.text.trim(),
        'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
        'password_encrypted': encryptedPassword,
        'url': _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'category': _selectedCategory,
        'is_favorite': _isFavorite,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.password != null) {
        await _supabase
            .from('passwords')
            .update(passwordData)
            .eq('id', widget.password!.id);
      } else {
        passwordData['created_at'] = DateTime.now().toIso8601String();
        await _supabase.from('passwords').insert(passwordData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.password != null ? 'Password updated' : 'Password saved'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.password != null ? 'Edit Password' : 'Add Password'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.password),
                        tooltip: 'Generate Password',
                        onPressed: _generatePassword,
                      ),
                      IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Website URL',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _savePassword,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.password != null ? 'Update Password' : 'Save Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
