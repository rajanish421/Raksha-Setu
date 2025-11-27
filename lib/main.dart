import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:raksha_setu/providers/user_provider.dart';
import 'constants/app_theme.dart';
import 'firebase_options.dart';
import 'utils/app_router.dart';
import 'utils/route_names.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
     options:  DefaultFirebaseOptions.currentPlatform,
  ); // you said Firebase already connected
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const DefenceApp()));
}

class DefenceApp extends StatelessWidget {
  const DefenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Defence Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
