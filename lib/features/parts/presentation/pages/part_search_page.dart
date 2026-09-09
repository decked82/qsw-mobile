import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/part.dart';
import '../../domain/use_cases/search_parts.dart';

class PartSearchPage extends StatefulWidget {
  PartSearchPage({super.key, SearchParts? searchParts})
    : _searchParts = searchParts ?? ServiceLocator.instance.searchParts;

  final SearchParts _searchParts;

  @override
  State<PartSearchPage> createState() => _PartSearchPageState();
}

class _PartSearchPageState extends State<PartSearchPage> {
  final _searchController = TextEditingController();

  List<Part> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget._searchParts(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = false;
      });

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToSearchParts(error.toString()))),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _results = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.partSearch)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('part_search_field'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: l10n.partCodeOrName,
                  hintText: l10n.enterPartCodeOrName,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    key: const Key('clear_search_button'),
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  key: const Key('search_parts_button'),
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? l10n.searching : l10n.search),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildResults()),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('add_part_from_search_button'),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.addPart);
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addPart),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    final l10n = AppLocalizations.of(context);

    if (!_hasSearched) {
      return Center(child: Text(l10n.enterPartCodeOrNameToSearch));
    }

    if (_results.isEmpty) {
      return Center(child: Text(l10n.noPartsFound));
    }

    return ListView.separated(
      key: const Key('search_results_list'),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final part = _results[index];

        return Card(
          child: ListTile(
            title: Text(part.partCode),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(part.name),
                if (part.specification != null &&
                    part.specification!.isNotEmpty)
                  Text(part.specification!),
                if (part.barcode != null && part.barcode!.isNotEmpty)
                  Text('${l10n.barcode}: ${part.barcode}'),
                Text('${l10n.unit}: ${part.unit}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
