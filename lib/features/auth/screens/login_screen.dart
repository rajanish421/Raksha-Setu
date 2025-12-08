// import 'package:flutter/material.dart';
// import '../../../constants/app_colors.dart';
// import '../../../custom_widgets/primary_button.dart';
// import '../../../utils/route_names.dart';
// import '../services/auth_service.dart';
// import '../services/firebase_otp_service.dart';
// import '../services/otp_service.dart';
// // later: import services, blocs, etc.
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _idController = TextEditingController();
//   final _passwordController = TextEditingController();
//
//   bool _isLoading = false;
//   bool _obscure = true;
//
//   final OtpService _otpService = FirebaseOtpService();
//
//
//   @override
//   void dispose() {
//     _idController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onLoginPressed() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       // 1. Check ID/Phone + Password using AuthService
//       final user = await AuthService.instance.loginWithIdentifierAndPassword(
//         identifier: _idController.text.trim(),
//         password: _passwordController.text.trim(),
//       );
//
//       // 2. Send OTP to registered phone
//       // Assuming Indian numbers stored without country code – prefix +91
//       final phoneWithCode = user.phone.startsWith('+')
//           ? user.phone
//           : '+91${user.phone.trim()}';
//
//       final verificationId =
//       await _otpService.sendOtp(phoneNumber: phoneWithCode);
//
//       if (!mounted) return;
//
//       // 3. Navigate to OTP verification screen
//       Navigator.pushNamed(
//         context,
//         RouteNames.otpVerification,
//         arguments: {
//           'verificationId': verificationId,
//           'phone': phoneWithCode,
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//
//     return Scaffold(
//       appBar: AppBar(
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               SizedBox(height: 60,),
//               Text(
//                 'Welcome back',
//                 style: textTheme.headlineLarge?.copyWith(fontSize: 52 , fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Use your Service ID (for soldier/veteran)\n'
//                     'or registered phone number (for family).',
//                 style: textTheme.bodyMedium,
//               ),
//               const SizedBox(height: 44),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _idController,
//                       decoration: const InputDecoration(
//                         labelText: 'Service ID / Phone',
//                         hintText: 'Enter your Service ID or phone number',
//                       ),
//                       validator: (value) {
//                         if (value == null || value.trim().isEmpty) {
//                           return 'Required';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: _obscure,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscure ? Icons.visibility_off : Icons.visibility,
//                             color: AppColors.textSecondary,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscure = !_obscure;
//                             });
//                           },
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.trim().isEmpty) {
//                           return 'Required';
//                         }
//                         if (value.length < 6) {
//                           return 'At least 6 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 8),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {
//                           // TODO: forgot password flow later
//                         },
//                         child: const Text('Forgot password?'),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     PrimaryButton(
//                       label: 'Login',
//                       onPressed: _onLoginPressed,
//                       isLoading: _isLoading,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';              // 👈 NEW
import '../../../constants/app_colors.dart';
import '../../../custom_widgets/primary_button.dart';
import '../../../utils/route_names.dart';
import '../services/auth_service.dart';
import '../services/firebase_otp_service.dart';
import '../services/otp_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  final OtpService _otpService = FirebaseOtpService();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Step 1: Email/Password login using your AuthService
      final userModel = await AuthService.instance.loginWithIdentifierAndPassword(
        identifier: _idController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // After this call, FirebaseAuth.currentUser is set
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception('Login failed. Please try again.');
      }

      // 2️⃣ Check if phone provider is already linked
      final providers = firebaseUser.providerData.map((p) => p.providerId).toList();
      final bool isPhoneLinked = providers.contains('phone');

      if (isPhoneLinked) {
        // ✅ OTP already verified earlier → Skip OTP screen

        if (!mounted) return;

        if (userModel.status == 'approved') {
          // Go directly to home
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.home,
                (route) => false,
          );
        } else if (userModel.status == 'pending') {
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.pendingApproval,
                (route) => false,
          );
        } else {
          // rejected / suspended / unknown
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your account is ${userModel.status}. Please contact HQ.',
              ),
            ),
          );
        }

        return; // ⛔ Stop here, don't send OTP
      }

      // 3️⃣ Phone NOT linked yet → send OTP and go to OTP screen

      // Assuming Indian numbers stored without country code – prefix +91
      final phoneWithCode = userModel.phone.startsWith('+')
          ? userModel.phone
          : '+91${userModel.phone.trim()}';

      final verificationId = await _otpService.sendOtp(
        phoneNumber: phoneWithCode,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        RouteNames.otpVerification,
        arguments: {
          'verificationId': verificationId,
          'phone': phoneWithCode,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                'Welcome back',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Use your Service ID (for soldier/veteran)\n'
                    'or registered phone number (for family).',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 44),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                        labelText: 'Service ID / Phone',
                        hintText: 'Enter your Service ID or phone number',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscure = !_obscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 6) {
                          return 'At least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: forgot password flow later
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Login',
                      onPressed: _onLoginPressed,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
