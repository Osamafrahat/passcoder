import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrashBinScreen extends StatefulWidget {
  const TrashBinScreen({super.key});
  @override
  State<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _trashItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      try {
        final passwords = await _supabase.from('passwords').select('id,title,deleted_at').eq('user_id', userId).not('deleted_at', 'is', null);
        final notes = await _supabase.from('notes').select('id,title,deleted_at').eq('user_id', userId).not('deleted_at', 'is', null);
        final cards = await _supabase.from('cards').select('id,cardholder_name,deleted_at').eq('user_id', userId).not('deleted_at', 'is', null);
        _trashItems = [
          ...passwords.map((p) => {...p, 'type': 'password'}),
          ...notes.map((n) => {...n, 'type': 'note'}),
          ...cards.map((c) => {...c, 'type': 'card'}),
        ];
        _trashItems.sort((a, b) {
          final aDate = a['deleted_at'] != null ? DateTime.parse(a['deleted_at']) : DateTime(2000);
          final bDate = b['deleted_at'] != null ? DateTime.parse(b['deleted_at']) : DateTime(2000);
          return bDate.compareTo(aDate);
        });
      } catch (_) {
        _trashItems = [];
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _restore(String table, String id) async {
    try {
      await _supabase.from(table).update({'deleted_at': null}).eq('id', id);
      _loadTrash();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _permanentDelete(String table, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: const Text('This cannot be undone. Delete permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _supabase.from(table).delete().eq('id', id);
        _loadTrash();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getTitle(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'password': return item['title'] ?? 'Untitled';
      case 'note': return item['title'] ?? 'Untitled';
      case 'card': return item['cardholder_name'] ?? 'Unknown Card';
      default: return 'Unknown';
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'password': return Icons.lock_outline;
      case 'note': return Icons.note_alt_outlined;
      case 'card': return Icons.credit_card_outlined;
      default: return Icons.help_outline;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'password': return Colors.blue;
      case 'note': return Colors.green;
      case 'card': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trash Bin')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashItems.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.delete_outline, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Trash is empty', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashItems.length,
                  itemBuilder: (_, i) {
                    final item = _trashItems[i];
                    final deletedAt = DateTime.parse(item['deleted_at']);
                    final daysLeft = 30 - DateTime.now().difference(deletedAt).inDays;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(_getIcon(item['type']), color: _getColor(item['type'])),
                        title: Text(_getTitle(item), style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('Type: ${item['type']} • ${daysLeft > 0 ? '$daysLeft days left' : 'Expiring soon'}',
                            style: TextStyle(fontSize: 12, color: daysLeft <= 7 ? Colors.red : theme.colorScheme.onSurfaceVariant)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.restore, color: Colors.green, size: 20),
                            onPressed: () => _restore('${item['type']}s', item['id']),
                            tooltip: 'Restore',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            onPressed: () => _permanentDelete('${item['type']}s', item['id']),
                            tooltip: 'Delete forever',
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
