import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/main/main_screen.dart';

class MfumoWaBeiApp extends StatelessWidget {
  const MfumoWaBeiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mfumo wa Bei',
      theme: AppTheme.light,
      initialRoute: MainScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) =>
            const ForgotPasswordScreen(),
        MainScreen.routeName: (context) => const MainScreen(),
      },
    );
  }
}
