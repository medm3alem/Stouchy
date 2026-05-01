import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false, _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
          email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.expense));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),
                // ── Logo Hero animé ─────────────────────────────
                FadeInDown(
                  child: Hero(
                    tag: 'app-logo',
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF9C27B0)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 44),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeInDown(delay: const Duration(milliseconds: 100),
                    child: Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.primary))),
                const SizedBox(height: 48),
                // ── Champs ──────────────────────────────────────
                FadeInLeft(delay: const Duration(milliseconds: 200),
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: l10n.email, prefixIcon: const Icon(Icons.email_outlined)),
                      validator: (v) => v!.contains('@') ? null : l10n.invalidEmail,
                    )),
                const SizedBox(height: 16),
                FadeInLeft(delay: const Duration(milliseconds: 300),
                    child: TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure)),
                      ),
                      validator: (v) => v!.length >= 6 ? null : l10n.passwordTooShort,
                    )),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () {}, child: Text(l10n.passwordForgotten))),
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 400),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(onPressed: _login, child: Text(l10n.login))),
                const SizedBox(height: 16),
                FadeIn(delay: const Duration(milliseconds: 500),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l10n.noAccount),
                      TextButton(onPressed: () => context.push('/register'), child: Text(l10n.register)),
                    ])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}