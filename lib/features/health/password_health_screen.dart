import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/password_health_service.dart';
import '../../core/encryption/encryption_service.dart';

class PasswordHealthScreen extends StatefulWidget {
  const PasswordHealthScreen({super.key});
  @override
  State<PasswordHealthScreen> createState() => _PasswordHealthScreenState();
}

class _PasswordHealthScreenState extends State<PasswordHealthScreen> {
  final _healthService = PasswordHealthService();
  final _encryption = EncryptionService();
  PasswordHealthResult? _result;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client.from('passwords').select().eq('user_id', userId);
      final passwords = <Map<String, dynamic>>[];
      for (final p in data) {
        String password = '';
        try { password = await _encryption.decryptData(p['password_encrypted']); } catch (_) {}
        passwords.add({...p, 'password': password});
      }
      _result = await _healthService.analyze(passwords);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Health'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _analyze),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? const Center(child: Text('No data'))
              : RefreshIndicator(
                  onRefresh: _analyze,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildScoreCard(theme),
                      const SizedBox(height: 20),
                      _buildStatsGrid(theme),
                      if (_result!.weak > 0) ...[
                        const SizedBox(height: 20),
                        _buildSection(theme, 'Weak Passwords', Icons.warning_amber, Colors.orange, '${_result!.weak} passwords need improvement'),
                      ],
                      if (_result!.reused > 0) ...[
                        const SizedBox(height: 12),
                        _buildSection(theme, 'Reused Passwords', Icons.copy, Colors.red, '${_result!.reused} passwords are reused'),
                        const SizedBox(height: 12),
                        ..._result!.reusedGroups.entries.map((e) => _buildReusedGroup(theme, e.key, e.value)),
                      ],
                      if (_result!.breached > 0) ...[
                        const SizedBox(height: 12),
                        _buildSection(theme, 'Breached Passwords', Icons.gpp_bad, Colors.deepOrange, '${_result!.breached} found in data breaches'),
                        const SizedBox(height: 8),
                        ..._result!.breachedPasswords.map((p) => _buildBreachedItem(theme, p['title'], p['count'])),
                      ],
                      if (_result!.oldPasswords > 0) ...[
                        const SizedBox(height: 12),
                        _buildSection(theme, 'Old Passwords', Icons.schedule, Colors.amber, '${_result!.oldPasswords} passwords older than 90 days'),
                      ],
                      if (_result!.weak == 0 && _result!.reused == 0 && _result!.breached == 0) ...[
                        const SizedBox(height: 40),
                        Center(
                          child: Column(children: [
                            Icon(Icons.verified, size: 64, color: Colors.green.shade400),
                            const SizedBox(height: 16),
                            Text('Excellent!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 8),
                            Text('Your passwords are healthy', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreCard(ThemeData theme) {
    final score = _result!.score;
    final color = score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: [
        Text('Health Score', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
        const SizedBox(height: 8),
        Text('${score.round()}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(score >= 80 ? 'Excellent' : score >= 50 ? 'Good' : 'Needs Improvement',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total', '${_result!.total}', Icons.lock, Colors.blue, theme),
        _buildStatCard('Strong', '${_result!.strong}', Icons.verified, Colors.green, theme),
        _buildStatCard('Weak', '${_result!.weak}', Icons.warning, Colors.orange, theme),
        _buildStatCard('Medium', '${_result!.medium}', Icons.remove, Colors.amber, theme),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _buildSection(ThemeData theme, String title, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        ])),
      ]),
    );
  }

  Widget _buildReusedGroup(ThemeData theme, String password, List<String> titles) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Used by:', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
        ...titles.map((t) => Text('  • $t', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildBreachedItem(ThemeData theme, String title, int count) {
    return Container(
      margin: const EdgeInsets.only(left: 12, top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.gpp_bad, color: Colors.deepOrange, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        Text('Found $count times', style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
      ]),
    );
  }
}
