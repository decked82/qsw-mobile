import 'package:flutter/material.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/parts/presentation/pages/add_part_page.dart';
import '../../features/parts/presentation/pages/part_search_page.dart';
import '../../features/parts/presentation/pages/parts_page.dart';

abstract final class AppRouter {
  static const String home = '/';
  static const String addPart = '/parts/add';
  static const String partSearch = '/parts/search';
  static const String parts = '/parts';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );

      case addPart:
        return MaterialPageRoute<void>(
          builder: (_) => AddPartPage(),
          settings: settings,
        );

      case partSearch:
        return MaterialPageRoute<void>(
          builder: (_) => PartSearchPage(),
          settings: settings,
        );

      case parts:
        return MaterialPageRoute<void>(
          builder: (_) => PartsPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const HomePage(),
          settings: settings,
        );
    }
  }
}
