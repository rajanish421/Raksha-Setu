import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../custom_widgets/primary_button.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/route_names.dart';
import '../services/auth_service.dart';
import '../services/firebase_otp_service.dart';
import '../services/otp_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpControllers =
  List.generate(6, (_) => TextEditingController(), growable: false);
  final _focusNodes =
  List.generate(6, (_) => FocusNode(), growable: false);

  bool _isLoading = false;
  int _secondsRemaining = 60;
  bool _canResend = false;

  late final SimpleTicker _ticker;
  final OtpService _otpService = FirebaseOtpService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _ticker = SimpleTicker((elapsed) {
      final seconds = 60 - elapsed.inSeconds;
      if (seconds <= 0) {
        _ticker.stop();
        if (mounted) {
          setState(() {
            _secondsRemaining = 0;
            _canResend = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsRemaining = seconds;
          });
        }
      }
    })..start();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _onVerifyPressed() async {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      _showMsg('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Verify OTP with Firebase
      await _otpService.verifyOtp(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // 2. Fetch current user profile
      final user = await AuthService.instance.getCurrentUserProfile();
      if (user == null) {
        throw Exception('User session not found. Please login again.');
      }

      if (!mounted) return;

      // 3. Route based on status
      if (user.status == 'pending') {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.pendingApproval,
              (route) => false,
        );
      } else if (user.status == 'approved') {
        // Later we will show Home (Group list).
        // For now, route to Splash or some placeholder.

        await Provider.of<UserProvider>(context, listen: false).loadUser();   // load user


        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.home,
              (route) => false,
        );
      } else if (user.status == 'rejected' || user.status == 'suspended') {
        _showMsg(
          'Your account is ${user.status}. Please contact HQ.',
        );
        // Optionally log the user out
      } else {
        // Default fallback
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteNames.pendingApproval,
              (route) => false,
        );
      }
    } catch (e) {
      print("error from otp screen --------- ${e.toString()}");
      _showMsg(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResendPressed() async {
    if (!_canResend) return;
    try {
      final newVerificationId = await _otpService.sendOtp(
        phoneNumber: widget.phone,
      );
      // Replace old verificationId with new one
      setState(() {
        _secondsRemaining = 60;
        _canResend = false;
      });
      _ticker.reset();
      _ticker.start();
      // You could also store newVerificationId in state, but for simplicity:
      // Create a new screen instance or use a state field.
      // For now, we just show a message.
      _showMsg('OTP resent to ${widget.phone}');
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phoneLabel = widget.phone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your identity',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'We’ve sent a 6-digit code to\n$phoneLabel.\n'
                    'Enter it below to continue.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                      (index) => _OtpBox(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_secondsRemaining > 0)
                    Text(
                      'Resend OTP in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: textTheme.bodyMedium,
                    )
                  else
                    TextButton(
                      onPressed: _canResend ? _onResendPressed : null,
                      child: const Text('Resend OTP'),
                    ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Verify & Continue',
                onPressed: _onVerifyPressed,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: const InputDecoration(
          counterText: '',
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Very simple ticker to update timer every second
class SimpleTicker {
  final void Function(Duration elapsed) _onTick;
  late final Stopwatch _stopwatch;
  late final Duration _tickInterval;
  bool _running = false;

  SimpleTicker(this._onTick, {Duration tickInterval = const Duration(seconds: 1)}) {
    _stopwatch = Stopwatch();
    _tickInterval = tickInterval;
  }

  void start() {
    if (_running) return;
    _running = true;
    _stopwatch.start();
    _tick();
  }

  void _tick() async {
    while (_running) {
      await Future.delayed(_tickInterval);
      if (!_running) break;
      _onTick(_stopwatch.elapsed);
    }
  }

  void reset() {
    _stopwatch.reset();
  }

  void stop() {
    _running = false;
    _stopwatch.stop();
  }

  void dispose() {
    stop();
  }
}
