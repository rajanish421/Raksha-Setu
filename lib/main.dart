import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:no_screenshot/no_screenshot.dart';
// import 'package:flutter_secure_screen/flutter_secure_screen.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/app_theme.dart';
import 'features/call/services/call_notification_service.dart';
import 'features/call/services/local_notification_service.dart';
import 'features/status/active_user_service.dart';
import 'firebase_options.dart';
import 'utils/app_router.dart';
import 'utils/route_names.dart';
import 'features/call/services/incoming_call_listener.dart';
import 'providers/user_provider.dart';

/// Global navigation key for incoming popup across entire app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final _noScreenshot = NoScreenshot.instance;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  // await FlutterSecureScreen.singleton.setAndroidScreenSecure(false);

  // await _noScreenshot.screenshotOff(); ---- block screenshot

  await _noScreenshot.screenshotOn();


  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );



  await LocalNotificationService.initialize();   // 👈 NEW
  await CallNotificationService.initialize();    // 👈 NEW

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const DefenceApp(),
    ),
  );
}

class DefenceApp extends StatefulWidget {
  const DefenceApp({super.key});

  @override
  State<DefenceApp> createState() => _DefenceAppState();
}

class _DefenceAppState extends State<DefenceApp> {

  @override
  void initState() {
    super.initState();


    // Start tracking active state
    ActiveUserService.instance.initialize();

    /// 🔥 Listen for authentication changes (important)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Start listening for calls ONLY when the user is logged in.
        IncomingCallListener.start(navigatorKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // required for popup anywhere
      title: 'Raksha Setu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
