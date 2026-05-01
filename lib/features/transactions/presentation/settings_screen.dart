import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../export/pdf_export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final txs = ref.watch(transactionsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apparence ────────────────────────────────
          _SectionTitle('Apparence'),
          Card(
            child: SwitchListTile(
              title: Text(l10n.darkMode),
              secondary: const Icon(Icons.dark_mode),
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Langue ────────────────────────────────────
          _SectionTitle(l10n.language),
          Card(
            child: Column(
              children: [
                _LangTile(flag: '🇫🇷', name: 'Français', code: 'fr', current: locale.languageCode, ref: ref),
                const Divider(height: 1),
                _LangTile(flag: '🇬🇧', name: 'English', code: 'en', current: locale.languageCode, ref: ref),
                const Divider(height: 1),
                _LangTile(flag: '🇹🇳', name: 'العربية', code: 'ar', current: locale.languageCode, ref: ref),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Notifications ─────────────────────────────
          _SectionTitle(l10n.notifications),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Activer les rappels quotidiens'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await NotificationService.scheduleDailyReminder();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rappel activé à 20h00 ✓')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_off),
                  title: const Text('Désactiver toutes les notifications'),
                  onTap: () => NotificationService.cancelAll(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Export ────────────────────────────────────
          _SectionTitle('Export'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Color(0xFFE53935)),
              title: Text(l10n.exportPdf),
              subtitle: Text('${txs.length} transactions'),
              trailing: const Icon(Icons.chevron_right),
              onTap: txs.isEmpty ? null : () => PdfExportService.exportTransactions(context, txs),
            ),
          ),
          const SizedBox(height: 16),

          // ── Infos ─────────────────────────────────────
          _SectionTitle('À propos'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Projet Flutter M2'),
                  trailing: const Text('2024/2025', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
  );
}

class _LangTile extends StatelessWidget {
  final String flag, name, code, current;
  final WidgetRef ref;
  const _LangTile({required this.flag, required this.name, required this.code, required this.current, required this.ref});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Text(flag, style: const TextStyle(fontSize: 24)),
    title: Text(name),
    trailing: current == code ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
    onTap: () => ref.read(localeProvider.notifier).setLocale(Locale(code)),
  );
}