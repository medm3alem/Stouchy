import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/transactions/presentation/home_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transactions_list_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/ai/chat_ai_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final authRoutes = ['/login', '/register'];
      final isAuthRoute = authRoutes.contains(state.matchedLocation);
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    // Animation de transition personnalisée
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/add-transaction',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          child: AddTransactionScreen(initialType: state.uri.queryParameters['type']),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
      ),
      GoRoute(path: '/transactions', builder: (_, __) => const TransactionsListScreen()),
      GoRoute(path: '/statistics',   builder: (_, __) => const StatisticsScreen()),
      GoRoute(path: '/budget-settings', builder: (_, __) => const BudgetScreen()),
      GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/chat-ai',      builder: (_, __) => const ChatAiScreen()),
      GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
    ],
  );
});