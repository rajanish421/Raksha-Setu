import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'utils/app_router.dart';
import 'utils/route_names.dart';

import 'features/call/services/incoming_call_listener.dart';
import 'providers/user_provider.dart';

/// Global Navigator Key (needed so popup can appear anywhere)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

    /// 🔥 Start call listener ONLY IF user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        IncomingCallListener.start(navigatorKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,   // 👈 Important
      title: 'Defence Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
