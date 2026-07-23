import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_verification_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/business/presentation/screens/business_setup_screen.dart';
import '../features/business/presentation/screens/business_type_screen.dart';
import '../features/business/presentation/screens/field_config_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/stock/presentation/screens/stock_screen.dart';
import '../features/stock/presentation/screens/add_product_screen.dart';
import '../features/stock/presentation/screens/product_detail_screen.dart';
import '../features/stock/presentation/screens/stock_in_screen.dart';
import '../features/sell/presentation/screens/sell_screen.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import '../features/transactions/presentation/screens/transactions_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../shared/widgets/home_shell.dart';

import '../core/errors/error_handler.dart';

final routerProvider = Provider<GoRouter>((ref) {
  String initialRoute = '/splash';

  return GoRouter(
    navigatorKey: ErrorHandler.navigatorKey,
    initialLocation: initialRoute,
    debugLogDiagnostics: false,
    routes: [
      // ── Auth & Onboarding ──────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => OtpVerificationScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: '/business-setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/business-type',
        builder: (context, state) => const BusinessTypeScreen(),
      ),
      GoRoute(
        path: '/field-config',
        builder: (context, state) => const FieldConfigScreen(),
      ),

      // ── Main Shell ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/stock',
            builder: (context, state) => const StockScreen(),
          ),
          GoRoute(
            path: '/sell',
            builder: (context, state) => const SellScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Stock Sub-routes (outside shell) ──────────────────────────────────────────────
      GoRoute(
        path: '/add-product',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddProductScreen(editProduct: extra?['product']);
        },
      ),
      GoRoute(
        path: '/product-detail/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/stock-in/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return StockInScreen(productId: id);
        },
      ),

      // ── Categories ──────────────────────────────────────────────
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),

      // ── Transactions ──────────────────────────────────────────────
      GoRoute(
        path: '/transactions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransactionsScreen(productId: extra?['productId']);
        },
      ),
    ],
  );
});
