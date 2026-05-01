import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../ai/ai_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _aiKeyController;

  @override
  void initState() {
    super.initState();
    _aiKeyController = TextEditingController();
    // On initialise le contrôleur avec la clé actuelle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _aiKeyController.text = ref.read(aiApiKeyProvider) ?? '';
    });
  }

  @override
  void dispose() {
    _aiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = ref.watch(themeProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Section Apparence ---
          _buildHeader(l10n.darkMode),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.darkMode),
              value: isDark,
              onChanged: (val) => ref.read(themeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 16),

          // --- Section IA ---
          _buildHeader("Intelligence Artificielle"),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text("Clé API Gemini", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Pour recevoir des conseils, créez une clé gratuite sur : aistudio.google.com",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiKeyController,
                    decoration: InputDecoration(
                      hintText: "Collez votre clé ici",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          ref.read(aiApiKeyProvider.notifier).setKey(_aiKeyController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Clé API sauvegardée ✓")),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- Section Langue ---
          _buildHeader(l10n.language),
          Card(
            child: Column(
              children: [
                _LangOption(label: 'Français', code: 'fr', current: currentLocale.languageCode),
                const Divider(height: 1),
                _LangOption(label: 'English', code: 'en', current: currentLocale.languageCode),
                const Divider(height: 1),
                _LangOption(label: 'العربية', code: 'ar', current: currentLocale.languageCode),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // --- Section Budget ---
          _buildHeader(l10n.budget),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.budget),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/budget-settings'),
            ),
          ),

          const SizedBox(height: 16),

          // --- Section Données ---
          _buildHeader("Données"),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Supprimer l'historique", style: TextStyle(color: Colors.red)),
              subtitle: const Text("Effacer toutes vos transactions définitivement"),
              onTap: () => _confirmDeleteHistory(context, ref),
            ),
          ),
          
          const SizedBox(height: 32),
          const Center(child: Text("Stouchy v1.0.0", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title.toUpperCase(), 
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  void _confirmDeleteHistory(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer TOUTES vos transactions ? Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(transactionRepositoryProvider).deleteAllTransactions();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Historique supprimé ✓")),
                );
              }
            },
            child: const Text("Supprimer tout"),
          ),
        ],
      ),
    );
  }
}

class _LangOption extends ConsumerWidget {
  final String label;
  final String code;
  final String current;
  const _LangOption({required this.label, required this.code, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = current == code;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () => ref.read(localeProvider.notifier).setLocale(Locale(code)),
    );
  }
}
