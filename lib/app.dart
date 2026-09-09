import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/localization/locale_storage.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class QswApp extends StatefulWidget {
  const QswApp({super.key, this.locale});

  final Locale? locale;

  static QswAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_QswAppScope>();

    assert(scope != null, 'QswApp.of() called outside of QswApp.');

    return scope!.state;
  }

  @override
  State<QswApp> createState() => QswAppState();
}

class QswAppState extends State<QswApp> {
  final LocaleStorage _localeStorage = LocaleStorage();

  Locale? _locale;
  bool _isLocaleLoaded = false;

  Locale? get locale => _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    if (widget.locale != null) {
      if (mounted) {
        setState(() {
          _isLocaleLoaded = true;
        });
      }
      return;
    }

    final savedLanguageCode = await _localeStorage.getSavedLocale();

    if (!mounted) {
      return;
    }

    if (savedLanguageCode != null) {
      _locale = Locale(savedLanguageCode);
    }

    setState(() {
      _isLocaleLoaded = true;
    });
  }

  Future<void> setLocale(Locale locale) async {
    setState(() {
      _locale = locale;
    });

    await _localeStorage.saveLocale(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocaleLoaded) {
      return const SizedBox.shrink();
    }

    return _QswAppScope(
      state: this,
      child: MaterialApp(
        title: 'QSW Mobile',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) {
            return const Locale('en');
          }

          for (final supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }

          return const Locale('en');
        },
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ko'), Locale('ru')],
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.home,
      ),
    );
  }
}

class _QswAppScope extends InheritedWidget {
  const _QswAppScope({required this.state, required super.child});

  final QswAppState state;

  @override
  bool updateShouldNotify(_QswAppScope oldWidget) {
    return state.locale != oldWidget.state.locale;
  }
}
