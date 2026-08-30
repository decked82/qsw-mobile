import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to search parts: $error')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Part Search')),
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
                  labelText: 'Part Code or Name',
                  hintText: 'Enter part code or name',
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
                  label: Text(_isSearching ? 'Searching...' : 'Search'),
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
                label: const Text('Add Part'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return const Center(child: Text('Enter a part code or name to search.'));
    }

    if (_results.isEmpty) {
      return const Center(child: Text('No parts found'));
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
                  Text('Barcode: ${part.barcode}'),
                Text('Unit: ${part.unit}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
