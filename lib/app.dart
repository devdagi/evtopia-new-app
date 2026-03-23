import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/register_screen.dart';
import 'screens/send_otp_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/blog_detail_screen.dart';
import 'screens/blogs_screen.dart';
import 'screens/liked_evs_screen.dart';
import 'models/notification_model.dart';
import 'screens/notification_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/post_car_screen.dart';
import 'screens/about_screen.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';
import 'widgets/connectivity_banner.dart';
import 'providers/connectivity_provider.dart';

/// Root widget: Login, or Verify Email (post-registration), or Home.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Full-screen loader only during initial session restore; login/register keep form visible.
    if (authState.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (authState.canShowMainApp) {
      return const MainShellScreen();
    }
    return const LoginScreen();
  }
}

/// Smooth slide + fade transition for auth flow (login → register → forgot → OTP → reset).
Route<T> _buildAuthRoute<T>(Widget page, [RouteSettings? settings]) {
  return PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: curve,
        reverseCurve: Curves.easeInCubic,
      );
      final fade = Tween<double>(begin: 0, end: 1).animate(curvedAnimation);
      final slide = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(curvedAnimation);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  );
}

class EvtopiaApp extends ConsumerWidget {
  const EvtopiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConnectivityAppWrapper(
      app: MaterialApp(
        title: 'Evtopia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
            primary: const Color(0xFF2E7D32),
          ),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
        initialRoute: '/',
        builder: (context, child) {
          final isConnected = ref.watch(connectivityProvider);
          return Stack(
            children: [
              child!,
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                        reverseCurve: Curves.easeInBack,
                      )),
                      child: child,
                    );
                  },
                  child: !isConnected
                      ? const ConnectivityBanner(key: ValueKey('offline_banner'))
                      : const SizedBox.shrink(key: ValueKey('online_placeholder')),
                ),
              ),
            ],
          );
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const AuthWrapper(),
              );
            case '/login':
              return _buildAuthRoute(const LoginScreen(), settings);
            case '/register':
              return _buildAuthRoute(const RegisterScreen(), settings);
            case '/home':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const MainShellScreen(),
              );
            case '/forgot-password':
              return _buildAuthRoute(const SendOtpScreen(), settings);
            case '/verify-otp':
              return _buildAuthRoute(const VerifyOtpScreen(), settings);
            case '/reset-password':
              return _buildAuthRoute(const ResetPasswordScreen(), settings);
            case '/edit-profile':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const EditProfileScreen(),
              );
            case '/change-password':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const ChangePasswordScreen(),
              );
            case '/liked-evs':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const LikedEvsScreen(),
              );
            case '/notifications':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const NotificationsScreen(),
              );
            case '/notification-detail': {
              final notification =
                  settings.arguments is NotificationModel
                      ? settings.arguments as NotificationModel
                      : null;
              if (notification == null) break;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => NotificationDetailScreen(
                  notification: notification,
                ),
              );
            }
            case '/blogs':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const BlogsScreen(),
              );
            case '/blog-detail': {
              final id = settings.arguments is int ? settings.arguments as int : null;
              if (id == null) break;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => BlogDetailScreen(postId: id),
              );
            }
            case '/post-car':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const PostCarScreen(),
              );
            case '/about':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const AboutScreen(),
              );
            case '/verify-email':
              return _buildAuthRoute(const VerifyEmailScreen(), settings);
            default:
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const AuthWrapper(),
              );
          }
        },
      ),
    );
  }
}
