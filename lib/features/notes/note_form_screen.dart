import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/note_model.dart';
import '../../core/encryption/encryption_service.dart';

class NoteFormScreen extends StatefulWidget {
  final NoteModel? note;
  const NoteFormScreen({super.key, this.note});
  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _encryption = EncryptionService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _loadContent();
    }
  }

  Future<void> _loadContent() async {
    try {
      final decrypted = await _encryption.decryptData(widget.note!.contentEncrypted);
      _contentController.text = decrypted;
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content required')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final encrypted = await _encryption.encryptData(_contentController.text);
      final data = {'user_id': userId, 'title': _titleController.text, 'content_encrypted': encrypted};
      if (widget.note != null) {
        await _supabase.from('notes').update(data).eq('id', widget.note!.id);
      } else {
        await _supabase.from('notes').insert(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        debugPrint('Note save error: $e');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: 'Note title',
              filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController, maxLines: null, minLines: 12,
            decoration: InputDecoration(hintText: 'Write your note...', alignLabelWithHint: true,
              filled: true, fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }
}
