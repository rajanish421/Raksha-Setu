import 'package:flutter_dotenv/flutter_dotenv.dart';

class ZegoConfig {
  static int get appId =>
      int.parse(dotenv.env['ZEGO_APP_ID'] ?? '0');

  static String get appSign =>
      dotenv.env['ZEGO_APP_SIGN'] ?? '';
}
