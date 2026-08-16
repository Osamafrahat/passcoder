import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/encryption/encryption_service.dart';
import '../../models/password_model.dart';
import '../passwords/password_detail_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});
  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _supabase = Supabase.instance.client;
  final _encryption = EncryptionService();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_search);
  }

  @override
  void dispose() {
    _controller.removeListener(_search);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final results = <Map<String, dynamic>>[];

      final passwordsData = await _supabase.from('passwords').select('id,user_id,title,username,password_encrypted,url,category,is_favorite,created_at,updated_at').eq('user_id', userId);
      for (final p in passwordsData) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final username = (p['username'] ?? '').toString().toLowerCase();
        final url = (p['url'] ?? '').toString().toLowerCase();
        if (title.contains(query) || username.contains(query) || url.contains(query)) {
          results.add({...p, 'type': 'password'});
        }
      }

      final notesData = await _supabase.from('notes').select('id,user_id,title,content_encrypted,category,created_at,updated_at').eq('user_id', userId);
      for (final n in notesData) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        if (title.contains(query)) {
          results.add({...n, 'type': 'note'});
        }
      }

      final cardsData = await _supabase.from('cards').select('id,user_id,cardholder_name,card_number_encrypted,card_type,created_at,updated_at').eq('user_id', userId);
      for (final c in cardsData) {
        final name = (c['cardholder_name'] ?? '').toString().toLowerCase();
        final type = (c['card_type'] ?? '').toString().toLowerCase();
        if (name.contains(query) || type.contains(query)) {
          results.add({...c, 'type': 'card'});
        }
      }

      setState(() => _results = results);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied!'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search passwords, notes, cards...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _controller.clear(); setState(() => _results = []); })
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(child: Text(_controller.text.isEmpty ? 'Type to search...' : 'No results found', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (_, i) => _buildResultItem(_results[i], theme),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item, ThemeData theme) {
    final type = item['type'] as String;
    final IconData icon;
    final Color color;
    final String title;
    final String subtitle;

    switch (type) {
      case 'password':
        icon = Icons.lock_outline;
        color = Colors.blue;
        title = item['title'] ?? '';
        subtitle = item['username'] ?? item['url'] ?? '';
        break;
      case 'note':
        icon = Icons.note_alt_outlined;
        color = Colors.green;
        title = item['title'] ?? '';
        subtitle = 'Note';
        break;
      case 'card':
        icon = Icons.credit_card_outlined;
        color = Colors.purple;
        title = item['cardholder_name'] ?? '';
        subtitle = item['card_type'] ?? 'Card';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
        title = 'Unknown';
        subtitle = '';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            if (type == 'password') {
              try {
                final decrypted = await _encryption.decryptData(item['password_encrypted']);
                _copyToClipboard(decrypted, 'Password');
              } catch (_) {
                _copyToClipboard('Decryption failed', 'Password');
              }
            } else if (type == 'note') {
              try {
                final decrypted = await _encryption.decryptData(item['content_encrypted']);
                _copyToClipboard(decrypted, 'Note content');
              } catch (_) {}
            }
          },
        ),
        onTap: () {
          if (type == 'password') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordDetailScreen(password: PasswordModel.fromJson(item))));
          }
        },
      ),
    );
  }
}
