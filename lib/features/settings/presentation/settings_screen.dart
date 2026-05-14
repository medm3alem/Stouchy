import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../ai/ai_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

import '../../security/providers/security_provider.dart';

import '../../auth/providers/profile_provider.dart';
import 'dart:io';

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
    final localImagePath = ref.watch(profilePhotoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Section Profil ---
          _buildHeader("Compte"),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                backgroundImage: localImagePath != null && File(localImagePath).existsSync()
                    ? FileImage(File(localImagePath))
                    : null,
                child: (localImagePath == null || !File(localImagePath).existsSync())
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(ref.watch(authRepositoryProvider).currentUser?.displayName ?? "Utilisateur"),
              subtitle: Text(ref.watch(authRepositoryProvider).currentUser?.email ?? ""),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(height: 16),

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

          // --- Section Sécurité ---
          _buildHeader("Sécurité"),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: const Text("Code PIN"),
                  subtitle: const Text("Protéger l'accès à l'application"),
                  value: ref.watch(securityProvider).hasPin,
                  onChanged: (val) {
                    if (val) {
                      _setupPin(context, ref);
                    } else {
                      _confirmRemovePin(context, ref);
                    }
                  },
                ),
                if (ref.watch(securityProvider).hasPin && ref.watch(securityProvider).canUseBiometrics)
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text("Biométrie"),
                    subtitle: const Text("Utiliser l'empreinte ou le visage"),
                    value: ref.watch(securityProvider).biometricsEnabled,
                    onChanged: (val) async {
                      await ref.read(securityProvider.notifier).setBiometricsEnabled(val);
                    },
                  ),
              ],
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

          // --- Section Devise ---
          _buildHeader("Devise"),
          Card(
            child: ListTile(
              leading: Text(currencyLogos[ref.watch(currencySettingsProvider)] ?? '💰', style: const TextStyle(fontSize: 20)),
              title: const Text("Devise préférée"),
              subtitle: Text('${ref.watch(currencySettingsProvider)} (${getCurrencySymbol(ref.watch(currencySettingsProvider))})'),
              trailing: const Icon(Icons.keyboard_arrow_down),
              onTap: () => _showCurrencyPicker(context, ref),
            ),
          ),

          const SizedBox(height: 16),

          // --- Section Budget ---
          _buildHeader(l10n.budget),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.budget),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/budget-settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text("Transactions Récurrentes"),
                  subtitle: const Text("Gérer les abonnements et salaires"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/recurring-transactions'),
                ),
              ],
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

  void _setupPin(BuildContext context, WidgetRef ref) {
    String firstPin = "";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Définir un code PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisissez un code à 4 chiffres"),
            const SizedBox(height: 20),
            Pinput(
              length: 4,
              obscureText: true,
              autofocus: true,
              onCompleted: (pin) {
                firstPin = pin;
                Navigator.pop(ctx, pin);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
        ],
      ),
    ).then((pin) {
      if (pin != null) {
        ref.read(securityProvider.notifier).setPin(pin);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Code PIN activé ✓")),
        );
      }
    });
  }

  void _confirmRemovePin(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Désactiver le code PIN"),
        content: const Text("Voulez-vous vraiment désactiver la protection par code PIN ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              ref.read(securityProvider.notifier).removePin();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Protection désactivée")),
              );
            },
            child: const Text("Désactiver"),
          ),
        ],
      ),
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

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choisir votre devise",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: currencyLogos.entries.map((e) {
                    return _CurrencyOption(
                      label: '${e.key} (${getCurrencySymbol(e.key)})',
                      code: e.key,
                      logo: e.value,
                      current: ref.watch(currencySettingsProvider),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
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

class _CurrencyOption extends ConsumerWidget {
  final String label;
  final String code;
  final String logo;
  final String current;
  const _CurrencyOption({
    required this.label, 
    required this.code, 
    required this.logo,
    required this.current
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = current == code;
    return ListTile(
      leading: Text(logo, style: const TextStyle(fontSize: 20)),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {
        ref.read(currencySettingsProvider.notifier).setCurrency(code);
        Navigator.pop(context);
      },
    );
  }
}
