import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/password_model.dart';
import '../../models/note_model.dart';
import '../../models/card_model.dart';
import '../encryption/encryption_service.dart';

class ExportImportService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EncryptionService _encryption = EncryptionService();

  Future<Map<String, dynamic>> exportData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final passwordsData = await _supabase.from('passwords').select().eq('user_id', userId);
    final notesData = await _supabase.from('notes').select().eq('user_id', userId);
    final cardsData = await _supabase.from('cards').select().eq('user_id', userId);

    final passwords = <Map<String, dynamic>>[];
    for (final p in passwordsData) {
      final model = PasswordModel.fromJson(p);
      String decryptedPassword = '';
      String? decryptedUsername;
      try { decryptedPassword = await _encryption.decryptData(model.passwordEncrypted); } catch (_) {}
      if (model.username != null) {
        try { decryptedUsername = await _encryption.decryptData(model.username!); } catch (_) {}
      }
      passwords.add({
        'title': model.title,
        'username': decryptedUsername ?? '',
        'password': decryptedPassword,
        'url': model.url ?? '',
        'notes': model.notes ?? '',
        'category': model.category,
        'is_favorite': model.isFavorite,
        'created_at': model.createdAt.toIso8601String(),
      });
    }

    final notes = <Map<String, dynamic>>[];
    for (final n in notesData) {
      final model = NoteModel.fromJson(n);
      String content = '';
      try { content = await _encryption.decryptData(model.contentEncrypted); } catch (_) {}
      notes.add({
        'title': model.title,
        'content': content,
        'category': model.category,
        'created_at': model.createdAt.toIso8601String(),
      });
    }

    final cards = <Map<String, dynamic>>[];
    for (final c in cardsData) {
      final model = CardModel.fromJson(c);
      String number = '', expiry = '', cvv = '';
      try { number = await _encryption.decryptData(model.cardNumberEncrypted); } catch (_) {}
      try { expiry = await _encryption.decryptData(model.expiryDateEncrypted); } catch (_) {}
      try { cvv = await _encryption.decryptData(model.cvvEncrypted); } catch (_) {}
      cards.add({
        'cardholder_name': model.cardholderName,
        'card_number': number,
        'expiry_date': expiry,
        'cvv': cvv,
        'card_type': model.cardType ?? '',
        'is_favorite': model.isFavorite,
        'created_at': model.createdAt.toIso8601String(),
      });
    }

    return {
      'app': 'PassCoder',
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'passwords': passwords,
      'notes': notes,
      'cards': cards,
    };
  }

  String exportToJson(Map<String, dynamic> data) => const JsonEncoder.withIndent('  ').convert(data);

  String exportToCsv(Map<String, dynamic> data) {
    final sb = StringBuffer();
    sb.writeln('Type,Title,Username,Password,URL,Notes,Category,Favorite');
    for (final p in data['passwords']) {
      sb.writeln('password,"${_csvEscape(p['title'])}","${_csvEscape(p['username'])}","${_csvEscape(p['password'])}","${_csvEscape(p['url'])}","${_csvEscape(p['notes'])}","${_csvEscape(p['category'])}",${p['is_favorite']}');
    }
    for (final n in data['notes']) {
      sb.writeln('note,"${_csvEscape(n['title'])}","",""," ","${_csvEscape(n['content'])}","${_csvEscape(n['category'])}",false');
    }
    for (final c in data['cards']) {
      sb.writeln('card,"${_csvEscape(c['cardholder_name'])}","${_csvEscape(c['card_number'])}","${_csvEscape(c['expiry_date'])}","${_csvEscape(c['cvv'])}","","${_csvEscape(c['card_type'])}",${c['is_favorite']}');
    }
    return sb.toString();
  }

  String _csvEscape(String s) => s.replaceAll('"', '""');

  Future<void> importFromJson(String jsonData) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    if (data['passwords'] != null) {
      for (final p in data['passwords']) {
        final encPassword = await _encryption.encryptData(p['password'] ?? '');
        String? encUsername;
        if (p['username'] != null && (p['username'] as String).isNotEmpty) {
          encUsername = await _encryption.encryptData(p['username']);
        }
        final insertData = {
          'user_id': userId,
          'title': p['title'] ?? 'Untitled',
          'username': encUsername,
          'password_encrypted': encPassword,
          'url': p['url'] ?? '',
          'notes': p['notes'] ?? '',
          'category': p['category'] ?? 'General',
        };
        try { insertData['is_favorite'] = p['is_favorite'] ?? false; } catch (_) {}
        try {
          await _supabase.from('passwords').insert(insertData);
        } catch (e) {
          insertData.remove('is_favorite');
          await _supabase.from('passwords').insert(insertData);
        }
      }
    }

    if (data['notes'] != null) {
      for (final n in data['notes']) {
        final encContent = await _encryption.encryptData(n['content'] ?? '');
        await _supabase.from('notes').insert({
          'user_id': userId,
          'title': n['title'] ?? 'Untitled',
          'content_encrypted': encContent,
          'category': n['category'] ?? 'General',
        });
      }
    }

    if (data['cards'] != null) {
      for (final c in data['cards']) {
        final encNumber = await _encryption.encryptData(c['card_number'] ?? '');
        final encExpiry = await _encryption.encryptData(c['expiry_date'] ?? '');
        final encCvv = await _encryption.encryptData(c['cvv'] ?? '');
        final insertData = {
          'user_id': userId,
          'cardholder_name': c['cardholder_name'] ?? '',
          'card_number_encrypted': encNumber,
          'expiry_date_encrypted': encExpiry,
          'cvv_encrypted': encCvv,
          'card_type': c['card_type'] ?? '',
        };
        try { insertData['is_favorite'] = c['is_favorite'] ?? false; } catch (_) {}
        try {
          await _supabase.from('cards').insert(insertData);
        } catch (e) {
          insertData.remove('is_favorite');
          await _supabase.from('cards').insert(insertData);
        }
      }
    }
  }
}
