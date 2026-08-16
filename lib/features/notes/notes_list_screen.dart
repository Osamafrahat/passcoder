import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/note_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'note_form_screen.dart';

class NotesListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final int? reloadTrigger;
  const NotesListScreen({super.key, this.onLogout, this.reloadTrigger});
  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();
  List<NoteModel> _notes = [];
  List<Map<String, String>> _decryptedNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() { super.initState(); loadNotes(); }

  @override
  void didUpdateWidget(NotesListScreen old) {
    super.didUpdateWidget(old);
    if (widget.reloadTrigger != old.reloadTrigger) loadNotes();
  }

  void loadNotes() async {
    setState(() { _isLoading = true; });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) { setState(() { _isLoading = false; }); return; }
      final data = await _supabase.from('notes').select().eq('user_id', userId).order('created_at', ascending: false);
      final notes = data.map((e) => NoteModel.fromJson(e)).where((n) => !n.isTrashed).toList();
      final decrypted = <Map<String, String>>[];
      for (final n in notes) {
        String content = '';
        try { content = await _encryption.decryptData(n.contentEncrypted); } catch (_) {}
        decrypted.add({'title': n.title, 'content': content, 'id': n.id});
      }
      setState(() { _notes = notes; _decryptedNotes = decrypted; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _toggleFavorite(NoteModel n) async {
    try {
      await _supabase.from('notes').update({'is_favorite': !n.isFavorite}).eq('id', n.id);
      loadNotes();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Run the SQL migration in Supabase to enable favorites'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _softDelete(NoteModel n) async {
    try {
      await _supabase.from('notes').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', n.id);
      loadNotes();
    } catch (_) {
      try { await _supabase.from('notes').delete().eq('id', n.id); loadNotes(); } catch (_) {}
    }
  }

  List<int> get _filteredIndices {
    if (_notes.isEmpty || _decryptedNotes.isEmpty || _notes.length != _decryptedNotes.length) return [];
    final indices = <int>[];
    for (int i = 0; i < _notes.length; i++) {
      final n = _notes[i];
      final nd = _decryptedNotes[i];
      final matchSearch = _searchQuery.isEmpty || nd['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) || nd['content']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'All' || n.category == _selectedCategory;
      if (matchSearch && matchCat) indices.add(i);
    }
    indices.sort((a, b) {
      final na = _notes[a], nb = _notes[b];
      if (na.isFavorite && !nb.isFavorite) return -1;
      if (!na.isFavorite && nb.isFavorite) return 1;
      return nb.createdAt.compareTo(na.createdAt);
    });
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final noteColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];
    final categories = ['All', ...{..._notes.map((n) => n.category)}];
    final filteredIndices = _filteredIndices;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Search notes...',
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
              : filteredIndices.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.note_alt_outlined, size: 48, color: cs.primary),
                      ),
                      const SizedBox(height: 20),
                      Text('No notes yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: cs.onSurface)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first note', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                      itemCount: filteredIndices.length,
                      itemBuilder: (_, i) {
                        final idx = filteredIndices[i];
                        final n = _notes[idx];
                        final nd = _decryptedNotes[idx];
                        final color = noteColors[i % noteColors.length];
                        final categoryColors = {'Personal': Colors.purple, 'Work': Colors.orange, 'Ideas': Colors.amber, 'Health': Colors.green, 'Finance': Colors.blue, 'Other': Colors.grey};
                        final catColor = categoryColors[n.category] ?? cs.primary;
                        return Material(
                          color: catColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(note: n))).then((_) => loadNotes()),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  if (n.isFavorite) Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                                  if (n.isFavorite) const SizedBox(width: 4),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: catColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                      child: Text(n.category, style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: Icon(Icons.more_vert, size: 18, color: cs.onSurfaceVariant),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        child: Row(children: [Icon(n.isFavorite ? Icons.star : Icons.star_border, size: 18, color: Colors.amber), const SizedBox(width: 8), Text(n.isFavorite ? 'Unfavorite' : 'Favorite')]),
                                        onTap: () => _toggleFavorite(n),
                                      ),
                                      PopupMenuItem(
                                        child: const Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(note: n))).then((_) => loadNotes()),
                                      ),
                                      PopupMenuItem(
                                        child: const Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                                        onTap: () => _softDelete(n),
                                      ),
                                    ],
                                  ),
                                ]),
                                const Spacer(),
                                Text(nd['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                Text(nd['content']!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
