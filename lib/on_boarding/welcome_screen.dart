import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../custom_widgets/primary_button.dart';
import '../utils/route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Namaste, Warrior 🇮🇳',
                  style: textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Secure HQ-controlled communication for\npersonnel, veterans & families.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Illustration / Hero section
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 60,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Closed Groups. No Leaks.',
                          style: textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All communication stays within\nHQ-authorised circles only.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Login',
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.login),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Register',
                isOutlined: true,
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.register),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
