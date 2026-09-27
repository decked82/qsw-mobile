import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              QswApp.of(context).setLocale(locale);
            },
            itemBuilder: (context) {
              final currentLocale = QswApp.of(context).locale;

              return [
                PopupMenuItem(
                  value: const Locale('en'),
                  child: _LanguageMenuItem(
                    label: 'English',
                    selected: currentLocale?.languageCode == 'en',
                  ),
                ),
                PopupMenuItem(
                  value: const Locale('ko'),
                  child: _LanguageMenuItem(
                    label: '한국어',
                    selected: currentLocale?.languageCode == 'ko',
                  ),
                ),
                PopupMenuItem(
                  value: const Locale('ru'),
                  child: _LanguageMenuItem(
                    label: 'Русский',
                    selected: currentLocale?.languageCode == 'ru',
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                l10n.appDescription,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _HomeMenuButton(icon: Icons.input, title: l10n.receiving),
                    _HomeMenuButton(icon: Icons.output, title: l10n.shipping),
                    _HomeMenuButton(
                      key: const Key('part_search_button'),
                      icon: Icons.search,
                      title: l10n.partSearch,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.partSearch);
                      },
                    ),
                    _HomeMenuButton(
                      key: const Key('inventory_button'),
                      icon: Icons.inventory_2_outlined,
                      title: l10n.inventory,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRouter.parts);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  const _HomeMenuButton({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: selected ? const Icon(Icons.check, size: 18) : null,
        ),
        Text(label),
      ],
    );
  }
}
