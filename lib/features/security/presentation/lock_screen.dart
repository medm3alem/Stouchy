import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/security_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final security = ref.read(securityProvider);
    // On force l'essai si l'option est activée dans les réglages
    if (security.biometricsEnabled) {
      await ref.read(securityProvider.notifier).authenticateBiometrics();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final security = ref.watch(securityProvider);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color: isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [AppColors.darkBg, AppColors.darkCard]
              : [Colors.white, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/SmallSquareLogoJpg.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Sécurité Stouchy',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Entrez votre code PIN pour continuer',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                child: Pinput(
                  controller: _pinController,
                  focusNode: _focusNode,
                  length: 4,
                  obscureText: true,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                  onCompleted: (pin) async {
                    final success = await ref.read(securityProvider.notifier).verifyPin(pin);
                    if (!success) {
                      setState(() {
                        _showError = true;
                        _pinController.clear();
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _showError = false);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_showError)
                FadeIn(
                  child: const Text(
                    'Code PIN incorrect',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 40),
              if (security.biometricsEnabled && security.canUseBiometrics)
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: IconButton(
                    icon: Icon(
                      security.hasFace ? Icons.face : Icons.fingerprint,
                      size: 50,
                      color: AppColors.primary,
                    ),
                    onPressed: _checkBiometrics,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                child: const Text('Déconnexion'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
