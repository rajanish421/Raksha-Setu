// import 'package:local_auth/local_auth.dart';
//
// class BiometricService {
//   final LocalAuthentication _localAuth = LocalAuthentication();
//
//   Future<bool> canCheckBiometric() async {
//     try {
//       return await _localAuth.canCheckBiometrics;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Future<bool> authenticate() async {
//     try {
//       final bool didAuthenticate = await _localAuth.authenticate(
//         localizedReason: 'Authenticate to access Raksha Setu',
//         biometricOnly: true,
//       );
//
//       return didAuthenticate;
//     } catch (e) {
//       return false;
//     }
//   }
// }
