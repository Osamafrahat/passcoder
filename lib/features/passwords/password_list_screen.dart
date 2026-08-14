import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'password_form_screen.dart';
import 'password_detail_screen.dart';
import '../health/password_health_screen.dart';
import '../settings/settings_screen.dart';
import '../trash/trash_bin_screen.dart';
import '../search/global_search_screen.dart';
import '../../core/theme/theme_service.dart';
import '../../core/services/auto_lock_service.dart';
import 'package:provider/provider.dart';

class PasswordListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const PasswordListScreen({super.key, this.onLogout});
  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();
  List<PasswordModel> _passwords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'newest';

  @override
  void initState() { super.initState(); _loadPasswords(); }

  Future<void> _loadPasswords() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase.from('passwords').select().eq('user_id', userId).order('created_at', ascending: false);
      setState(() { _passwords = data.map((e) => PasswordModel.fromJson(e)).where((p) => !p.isTrashed).toList(); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _toggleFavorite(PasswordModel p) async {
    try {
      await _supabase.from('passwords').update({'is_favorite': !p.isFavorite}).eq('id', p.id);
      _loadPasswords();
    } catch (_) {}
  }

  Future<void> _softDelete(PasswordModel p) async {
    try {
      await _supabase.from('passwords').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', p.id);
      _loadPasswords();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${p.title}" moved to trash'), action: SnackBarAction(label: 'Undo', onPressed: () async {
          await _supabase.from('passwords').update({'deleted_at': null}).eq('id', p.id);
          _loadPasswords();
        })),
      );
    } catch (_) {}
  }

  Future<void> _reorderPasswords(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _passwords.removeAt(oldIndex);
      _passwords.insert(newIndex, item);
    });
    try {
      for (var i = 0; i < _passwords.length; i++) {
        await _supabase.from('passwords').update({'sort_order': i}).eq('id', _passwords[i].id);
      }
    } catch (_) {}
  }

  Future<void> _quickCopy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label copied! Auto-clearing in 30s...'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
    Future.delayed(const Duration(seconds: 30), () async {
      try { await Clipboard.setData(const ClipboardData(text: '')); } catch (_) {}
    });
  }

  List<PasswordModel> get _filtered {
    var list = _passwords.where((p) {
      final match = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) || (p.username ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final cat = _selectedCategory == 'All' || p.category == _selectedCategory;
      return match && cat;
    }).toList();
    list.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      switch (_sortBy) {
        case 'oldest': return a.createdAt.compareTo(b.createdAt);
        case 'title': return a.title.compareTo(b.title);
        default: return b.createdAt.compareTo(a.createdAt);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ['All', ...{..._passwords.map((p) => p.category)}];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passwords'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()))),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'health', child: Row(children: [Icon(Icons.health_and_safety, size: 18), SizedBox(width: 8), Text('Password Health')])),
              const PopupMenuItem(value: 'trash', child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 8), Text('Trash Bin')])),
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 8), Text('Settings')])),
              if (widget.onLogout != null)
                const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Sign Out', style: TextStyle(color: Colors.red))])),
            ],
            onSelected: (v) {
              if (v == 'health') Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordHealthScreen()));
              else if (v == 'trash') Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashBinScreen()));
              else if (v == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
                themeService: context.read<ThemeService>(),
                autoLockService: context.read<AutoLockService>(),
              )));
              else if (v == 'logout') widget.onLogout?.call();
            },
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
                const SizedBox(height: 8),
                Row(children: [
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
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    onSelected: (v) => setState(() => _sortBy = v),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'newest', child: Text('Newest first')),
                      const PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
                      const PopupMenuItem(value: 'title', child: Text('Alphabetical')),
                    ],
                  ),
                ]),
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
                    : RefreshIndicator(
                      onRefresh: _loadPasswords,
                      child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: _filtered.length,
                          onReorder: (oldIndex, newIndex) {
                            final item = _filtered[oldIndex];
                            setState(() {
                              _passwords.removeWhere((p) => p.id == item.id);
                              if (newIndex > oldIndex) newIndex -= 1;
                              final insertAt = newIndex < _passwords.length ? newIndex : _passwords.length;
                              _passwords.insert(insertAt, item);
                            });
                            _reorderPasswords(oldIndex, newIndex);
                          },
                          buildDefaultDragHandles: false,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            return Padding(
                              key: ValueKey(p.id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _PasswordCard(
                              password: p,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordDetailScreen(password: p))).then((_) => _loadPasswords()),
                              onFavorite: () => _toggleFavorite(p),
                              onQuickCopy: () async {
                                try {
                                  final decrypted = await _encryption.decryptData(p.passwordEncrypted);
                                  _quickCopy(decrypted, 'Password');
                                } catch (_) {
                                  _quickCopy('Decryption failed', 'Password');
                                }
                              },
                              onDelete: () => _softDelete(p),
                              ),
                            );
                          },
                        ),
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
  final VoidCallback onFavorite;
  final VoidCallback onQuickCopy;
  final VoidCallback onDelete;

  const _PasswordCard({required this.password, required this.onTap, required this.onFavorite, required this.onQuickCopy, required this.onDelete});

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
              border: Border.all(color: password.isFavorite ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
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
                    Row(children: [
                      if (password.isFavorite) ...[
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                      ],
                      Expanded(child: Text(password.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 3),
                    Text(password.username ?? '', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(password.category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (_) => [
                    PopupMenuItem(child: Row(children: [
                      Icon(password.isFavorite ? Icons.star : Icons.star_border, size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(password.isFavorite ? 'Unfavorite' : 'Favorite'),
                    ]), onTap: onFavorite),
                    const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Quick Copy')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                  ],
                  onSelected: (v) {
                    if (v == 'copy') onQuickCopy();
                    else if (v == 'delete') onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
