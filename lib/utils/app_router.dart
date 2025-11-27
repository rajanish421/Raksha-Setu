import 'package:flutter/material.dart';
import 'package:raksha_setu/features/home/screens/home_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/pending_approval_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../on_boarding/splash_screen.dart';
import '../on_boarding/welcome_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      case RouteNames.splash:
        return _buildRoute(const SplashScreen(), settings);

      case RouteNames.welcome:
        return _buildRoute(const WelcomeScreen(), settings);

      case RouteNames.login:
        return _buildRoute(const LoginScreen(), settings);

      case RouteNames.register:
        return _buildRoute(const RegisterScreen(), settings);


      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(
            verificationId: args?['verificationId'] as String? ?? '',
            phone: args?['phone'] as String? ?? '',
          ),
          settings,
        );

      case RouteNames.pendingApproval:
        return _buildRoute(const PendingApprovalScreen(), settings);

    // case RouteNames.home:
    //   return _buildRoute(const HomeScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }
}
