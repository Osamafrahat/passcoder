import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import 'password_form_screen.dart';
import 'password_detail_screen.dart';

class PasswordListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const PasswordListScreen({super.key, this.onLogout});
  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<PasswordModel> _passwords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() { super.initState(); _loadPasswords(); }

  Future<void> _loadPasswords() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase.from('passwords').select().eq('user_id', userId).order('created_at', ascending: false);
      setState(() { _passwords = data.map((e) => PasswordModel.fromJson(e)).toList(); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  List<PasswordModel> get _filtered => _passwords.where((p) {
    final match = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) || (p.username ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    final cat = _selectedCategory == 'All' || p.category == _selectedCategory;
    return match && cat;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ...{..._passwords.map((p) => p.category)}];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passwords'),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_passwords',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordFormScreen())).then((_) => _loadPasswords()),
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(hintText: 'Search passwords...', prefixIcon: const Icon(Icons.search, size: 22),
                    filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal, itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      final selected = _selectedCategory == c;
                      return FilterChip(label: Text(c, style: TextStyle(fontSize: 13, color: selected ? Colors.white : theme.colorScheme.onSurface)),
                        selected: selected, onSelected: (_) => setState(() => _selectedCategory = c),
                        selectedColor: theme.colorScheme.primary, backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.lock_open_outlined, size: 48, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text('No passwords yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap + to add your first password', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final p = _filtered[i];
                          return _PasswordCard(
                            password: p,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordDetailScreen(password: p))).then((_) => _loadPasswords()),
                            onDelete: () async {
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
                                await _supabase.from('passwords').delete().eq('id', p.id);
                                _loadPasswords();
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final PasswordModel password;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PasswordCard({required this.password, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColors = {
      'Social': Colors.blue, 'Finance': Colors.green, 'Work': Colors.orange, 'Personal': Colors.purple, 'Other': Colors.grey,
    };
    final color = categoryColors[password.category] ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.lock_outline, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(password.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(password.username ?? '', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(password.category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      child: const Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
