import 'package:flutter/material.dart';
import '../../core/theme/theme_service.dart';
import '../../core/services/auto_lock_service.dart';
import '../../core/services/export_import_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeService themeService;
  final AutoLockService autoLockService;
  const SettingsScreen({super.key, required this.themeService, required this.autoLockService});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _exportService = ExportImportService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Appearance', theme),
          _buildThemeToggle(theme),
          const SizedBox(height: 24),
          _buildSectionHeader('Security', theme),
          _buildAutoLockOption(theme),
          const SizedBox(height: 24),
          _buildSectionHeader('Data', theme),
          _buildExportOption(theme),
          const SizedBox(height: 8),
          _buildImportOption(theme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold, color: theme.colorScheme.primary,
      )),
    );
  }

  Widget _buildThemeToggle(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile(
        title: const Text('Dark Mode'),
        subtitle: const Text('Switch between dark and light theme'),
        secondary: Icon(widget.themeService.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
        value: widget.themeService.themeMode == ThemeMode.dark,
        onChanged: (_) => widget.themeService.toggleTheme(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildAutoLockOption(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(Icons.lock_clock),
        title: const Text('Auto-Lock Timer'),
        subtitle: Text('Lock after ${widget.autoLockService.timeoutMinutes} minutes of inactivity'),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () => _showAutoLockDialog(theme),
      ),
    );
  }

  void _showAutoLockDialog(ThemeData theme) {
    final options = [0, 1, 2, 5, 10, 15, 30];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Lock Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((m) => RadioListTile<int>(
            title: Text(m == 0 ? 'Never' : '$m minutes'),
            value: m,
            groupValue: widget.autoLockService.timeoutMinutes,
            onChanged: (v) {
              widget.autoLockService.setTimeout(v ?? 5);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildExportOption(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Export Data'),
        subtitle: const Text('Export as JSON or CSV'),
        trailing: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: _isExporting ? null : _showExportDialog,
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose export format:'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _export('json'); }, child: const Text('JSON')),
          TextButton(onPressed: () { Navigator.pop(ctx); _export('csv'); }, child: const Text('CSV')),
        ],
      ),
    );
  }

  Future<void> _export(String format) async {
    setState(() => _isExporting = true);
    try {
      final data = await _exportService.exportData();
      final content = format == 'json' ? _exportService.exportToJson(data) : _exportService.exportToCsv(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/passcoder_export.$format');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'PassCoder Export');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isExporting = false);
  }

  Widget _buildImportOption(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(Icons.upload),
        title: const Text('Import Data'),
        subtitle: const Text('Import from JSON backup'),
        trailing: const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: _importData,
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(hintText: 'Paste your JSON backup here...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _exportService.importFromJson(controller.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful!'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
