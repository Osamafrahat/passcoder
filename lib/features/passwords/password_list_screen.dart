import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'password_detail_screen.dart';

class PasswordListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final int? reloadTrigger;
  const PasswordListScreen({super.key, this.onLogout, this.reloadTrigger});
  @override
  PasswordListScreenState createState() => PasswordListScreenState();
}

class PasswordListScreenState extends State<PasswordListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();
  List<PasswordModel> _passwords = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'newest';

  @override
  void initState() { super.initState(); loadPasswords(); }

  @override
  void didUpdateWidget(PasswordListScreen old) {
    super.didUpdateWidget(old);
    if (widget.reloadTrigger != old.reloadTrigger) loadPasswords();
  }

  Future<void> loadPasswords() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) { setState(() { _isLoading = false; }); return; }
      final data = await _supabase.from('passwords').select().eq('user_id', userId).order('created_at', ascending: false);
      setState(() { _passwords = data.map((e) => PasswordModel.fromJson(e)).where((p) => !p.isTrashed).toList(); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _toggleFavorite(PasswordModel p) async {
    try {
      await _supabase.from('passwords').update({'is_favorite': !p.isFavorite}).eq('id', p.id);
      loadPasswords();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run the SQL migration in Supabase to enable favorites'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _softDelete(PasswordModel p) async {
    try {
      await _supabase.from('passwords').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', p.id);
      loadPasswords();
    } catch (_) {
      try {
        await _supabase.from('passwords').delete().eq('id', p.id);
        loadPasswords();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _quickCopy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied! Auto-clearing in 30s...'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
    Future.delayed(const Duration(seconds: 30), () async { try { await Clipboard.setData(const ClipboardData(text: '')); } catch (_) {} });
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
    final cs = theme.colorScheme;
    final categories = ['All', ...{..._passwords.map((p) => p.category)}];

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Search passwords...',
              hintStyle: TextStyle(color: cs.onSurfaceVariant),
              prefixIcon: Icon(Icons.search, size: 22, color: cs.onSurfaceVariant),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = categories[i];
              final selected = _selectedCategory == c;
              return FilterChip(
                label: Text(c, style: TextStyle(fontSize: 13, color: selected ? Colors.white : cs.onSurface)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = c),
                selectedColor: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open_outlined, size: 48, color: cs.primary),
                          const SizedBox(height: 16),
                          Text('No passwords yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: cs.onSurface)),
                          const SizedBox(height: 8),
                          Text('Tap + to add your first password', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadPasswords,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final p = _filtered[i];
                          return _PasswordCard(
                            password: p,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordDetailScreen(password: p))).then((_) => loadPasswords()),
                            onFavorite: () => _toggleFavorite(p),
                            onQuickCopy: () async {
                              try { final d = await _encryption.decryptData(p.passwordEncrypted); _quickCopy(d, 'Password'); } catch (_) { _quickCopy('Decryption failed', 'Password'); }
                            },
                            onDelete: () => _softDelete(p),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PasswordCard extends StatelessWidget {
  final PasswordModel password;
  final VoidCallback onTap, onFavorite, onQuickCopy, onDelete;
  const _PasswordCard({required this.password, required this.onTap, required this.onFavorite, required this.onQuickCopy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final categoryColors = {'Social': Colors.blue, 'Finance': Colors.green, 'Work': Colors.orange, 'Personal': Colors.purple, 'Other': Colors.grey};
    final color = categoryColors[password.category] ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: password.isFavorite ? cs.primary.withOpacity(0.5) : cs.outlineVariant.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.lock_outline, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (password.isFavorite) ...[Icon(Icons.star, size: 14, color: Colors.amber.shade600), const SizedBox(width: 4)],
                  Expanded(child: Text(password.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 3),
                Text(password.username ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(password.category, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, size: 20, color: cs.onSurfaceVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                itemBuilder: (_) => [
                  PopupMenuItem(child: Row(children: [
                    Icon(password.isFavorite ? Icons.star : Icons.star_border, size: 18, color: Colors.amber),
                    const SizedBox(width: 8), Text(password.isFavorite ? 'Unfavorite' : 'Favorite'),
                  ]), onTap: onFavorite),
                  const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Quick Copy')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
                onSelected: (v) { if (v == 'copy') onQuickCopy(); else if (v == 'delete') onDelete(); },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
