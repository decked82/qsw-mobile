import 'package:flutter/material.dart';

import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class QswApp extends StatelessWidget {
  const QswApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QSW Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.home,
    );
  }
}
