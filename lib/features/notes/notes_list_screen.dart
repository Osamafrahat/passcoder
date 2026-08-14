import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/note_model.dart';
import '../../core/encryption/encryption_service.dart';
import 'note_form_screen.dart';

class NotesListScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  const NotesListScreen({super.key, this.onLogout});
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

  @override
  void initState() { super.initState(); _loadNotes(); }

  Future<void> _loadNotes() async {
    setState(() { _isLoading = true; _decryptedNotes = []; });
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase.from('notes').select().eq('user_id', userId).order('created_at', ascending: false);
      final notes = data.map((e) => NoteModel.fromJson(e)).toList();
      final decrypted = <Map<String, String>>[];
      for (final n in notes) {
        String content = '';
        try { content = await _encryption.decryptData(n.contentEncrypted); } catch (_) {}
        decrypted.add({'title': n.title, 'content': content, 'id': n.id});
      }
      setState(() { _notes = notes; _decryptedNotes = decrypted; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_notes',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteFormScreen())).then((_) => _loadNotes()),
        icon: const Icon(Icons.add),
        label: const Text('Add Note'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(hintText: 'Search notes...', prefixIcon: const Icon(Icons.search, size: 22),
                  filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator())
                : _decryptedNotes.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(Icons.note_alt_outlined, size: 48, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 20),
                        Text('No notes yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Tap + to add your first note', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ]))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                        itemCount: _decryptedNotes.length,
                        itemBuilder: (_, i) {
                          final nd = _decryptedNotes[i];
                          final n = _notes[i];
                          final color = noteColors[i % noteColors.length];
                          return Material(
                            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(note: n))).then((_) => _loadNotes()),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                    const Spacer(),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert, size: 18, color: color),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          child: const Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(note: n))).then((_) => _loadNotes()),
                                        ),
                                        PopupMenuItem(
                                          child: const Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
                                          onTap: () async {
                                            await _supabase.from('notes').delete().eq('id', n.id);
                                            _loadNotes();
                                          },
                                        ),
                                      ],
                                    ),
                                  ]),
                                  const Spacer(),
                                  Text(nd['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 6),
                                  Text(nd['content']!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
