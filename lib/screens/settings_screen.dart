import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  final StorageService storage;
  final Color accentColor;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.accentColor,
  });

  void _exportData(BuildContext context) {
    final data = storage.exportData();
    Clipboard.setData(ClipboardData(text: data));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup copied to clipboard! Save it somewhere safe.')),
    );
  }

  void _importData(BuildContext context) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim() ?? '';
    
    if (text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty.')),
        );
      }
      return;
    }

    if (context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Data'),
          content: const Text('This will overwrite all your current tasks, streaks, and journals. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        final success = await storage.importData(text);
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data restored successfully! Please restart the app.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to restore data. Invalid backup string.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Backup & Restore',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.copy_rounded, color: accentColor),
            title: const Text('Export Backup to Clipboard'),
            subtitle: const Text('Save your data securely'),
            onTap: () => _exportData(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.paste_rounded, color: accentColor),
            title: const Text('Restore Backup from Clipboard'),
            subtitle: const Text('Overwrite current data'),
            onTap: () => _importData(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }
}
