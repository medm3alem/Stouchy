import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';

import '../providers/profile_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  File? _image;
  bool _loading = false, _obscure = true;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim(),
          );
          
      // Sauvegarde de l'image locale après inscription réussie
      if (_image != null) {
        await ref.read(profilePhotoProvider.notifier).updatePhoto(_image!.path);
      }

      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.expense));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                FadeInDown(
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/images/SmallSquareLogoJpg.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(l10n.register,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
                const SizedBox(height: 24),
                // --- Avatar Picker ---
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: "Nom complet",
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => v!.length < 2 ? "Nom trop court" : null,
                    )),
                const SizedBox(height: 16),
                FadeInLeft(
                    delay: const Duration(milliseconds: 300),
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(Icons.email_outlined)),
                      validator: (v) => v!.contains('@') ? null : l10n.invalidEmail,
                    )),
                const SizedBox(height: 16),
                FadeInLeft(
                    delay: const Duration(milliseconds: 400),
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
                const SizedBox(height: 16),
                FadeInLeft(
                    delay: const Duration(milliseconds: 500),
                    child: TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        prefixIcon: const Icon(Icons.lock_reset),
                      ),
                      validator: (v) => v == _passCtrl.text ? null : l10n.passwordMismatch,
                    )),
                const SizedBox(height: 32),
                FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(onPressed: _register, child: Text(l10n.register))),
                const SizedBox(height: 16),
                FadeIn(
                    delay: const Duration(milliseconds: 700),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l10n.alreadyAccount),
                      TextButton(onPressed: () => context.pop(), child: Text(l10n.login)),
                    ])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
