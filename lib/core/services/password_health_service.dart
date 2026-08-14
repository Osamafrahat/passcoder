import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class BreachCheckService {
  static const String _apiUrl = 'https://api.pwnedpasswords.com/range/';

  Future<int> checkPassword(String password) async {
    try {
      final sha1Hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
      final prefix = sha1Hash.substring(0, 5);
      final suffix = sha1Hash.substring(5);

      final response = await http.get(Uri.parse('$_apiUrl$prefix'));
      if (response.statusCode != 200) return 0;

      final lines = response.body.split('\r\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts[0] == suffix) {
          return int.parse(parts[1].trim());
        }
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

class PasswordHealthResult {
  final int total;
  final int weak;
  final int medium;
  final int strong;
  final int reused;
  final int breached;
  final int oldPasswords;
  final Map<String, List<String>> reusedGroups;
  final List<Map<String, dynamic>> breachedPasswords;
  final double score;

  PasswordHealthResult({
    required this.total,
    required this.weak,
    required this.medium,
    required this.strong,
    required this.reused,
    required this.breached,
    required this.oldPasswords,
    required this.reusedGroups,
    required this.breachedPasswords,
    required this.score,
  });
}

class PasswordHealthService {
  final BreachCheckService _breachService = BreachCheckService();

  int calculateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) score++;
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) score++;
    return score;
  }

  String strengthLabel(int score) {
    if (score <= 3) return 'Weak';
    if (score <= 5) return 'Medium';
    return 'Strong';
  }

  double strengthPercent(int score) => (score / 8).clamp(0.0, 1.0);

  Future<PasswordHealthResult> analyze(List<Map<String, dynamic>> passwords) async {
    int weak = 0, medium = 0, strong = 0;
    final Map<String, List<String>> passwordGroups = <String, List<String>>{};
    int breachedCount = 0;
    final List<Map<String, dynamic>> breachedList = [];
    int oldCount = 0;
    final now = DateTime.now();

    for (final p in passwords) {
      final password = p['password'] as String? ?? '';
      final title = p['title'] as String? ?? '';
      if (password.isEmpty) continue;

      final score = calculateStrength(password);
      if (score <= 3) weak++;
      else if (score <= 5) medium++;
      else strong++;

      final normalized = password.toLowerCase();
      passwordGroups.putIfAbsent(normalized, () => []);
      passwordGroups[normalized]!.add(title);

      final createdAt = p['created_at'];
      if (createdAt != null) {
        final created = DateTime.parse(createdAt.toString());
        if (now.difference(created).inDays > 90) oldCount++;
      }
    }

    final reusedGroups = <String, List<String>>{};
    int reusedCount = 0;
    for (final entry in passwordGroups.entries) {
      if (entry.value.length > 1) {
        reusedGroups[entry.key] = entry.value;
        reusedCount += entry.value.length;
      }
    }

    for (final p in passwords) {
      final password = p['password'] as String? ?? '';
      if (password.isEmpty) continue;
      final count = await _breachService.checkPassword(password);
      if (count > 0) {
        breachedCount++;
        breachedList.add({'title': p['title'], 'count': count});
      }
    }

    final total = passwords.length;
    double score = 100;
    if (total > 0) {
      score -= (weak / total * 40);
      score -= (reusedCount / total * 30);
      score -= (breachedCount / total * 30);
    }

    return PasswordHealthResult(
      total: total,
      weak: weak,
      medium: medium,
      strong: strong,
      reused: reusedCount,
      breached: breachedCount,
      oldPasswords: oldCount,
      reusedGroups: reusedGroups,
      breachedPasswords: breachedList,
      score: score.clamp(0, 100),
    );
  }
}
