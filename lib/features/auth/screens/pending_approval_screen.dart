import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/route_names.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security, size: 90, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  "Account Under Review",
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  "HQ is verifying your identity.\n"
                      "You will be notified once approved.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      RouteNames.login,
                          (r) => false,
                    );
                  },
                  child: const Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
