import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/part.dart';
import '../../domain/use_cases/delete_part.dart';
import '../../domain/use_cases/get_parts.dart';

class PartsPage extends StatefulWidget {
  PartsPage({super.key, GetParts? getParts, DeletePart? deletePart})
    : _getParts = getParts ?? ServiceLocator.instance.getParts,
      _deletePart = deletePart ?? ServiceLocator.instance.deletePart;

  final GetParts _getParts;
  final DeletePart _deletePart;

  @override
  State<PartsPage> createState() => _PartsPageState();
}

class _PartsPageState extends State<PartsPage> {
  late Future<List<Part>> _partsFuture;

  @override
  void initState() {
    super.initState();
    _partsFuture = widget._getParts();
  }

  void _reload() {
    setState(() {
      _partsFuture = widget._getParts();
    });
  }

  Future<void> _deletePart(Part part) async {
    if (part.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Part'),
          content: Text('Are you sure you want to delete "${part.partCode}"?'),
          actions: [
            TextButton(
              key: const Key('cancel_delete_button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_delete_button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget._deletePart(part.id!);

      if (!mounted) {
        return;
      }

      _reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Part deleted successfully')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete part: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts'),
        actions: [
          IconButton(
            key: const Key('refresh_parts_button'),
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<Part>>(
        future: _partsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(onRetry: _reload);
          }

          final parts = snapshot.data ?? [];

          if (parts.isEmpty) {
            return const _EmptyPartsView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _partsFuture;
            },
            child: ListView.separated(
              key: const Key('parts_list'),
              padding: const EdgeInsets.all(16),
              itemCount: parts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final part = parts[index];

                return _PartCard(
                  key: ValueKey('part_${part.id}'),
                  part: part,
                  onDelete: () => _deletePart(part),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({super.key, required this.part, required this.onDelete});

  final Part part;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          part.partCode,
          key: Key('part_code_${part.id}'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(part.name),
              if (part.specification != null && part.specification!.isNotEmpty)
                Text(
                  part.specification!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (part.barcode != null && part.barcode!.isNotEmpty)
                Text(
                  'Barcode: ${part.barcode}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              Text(
                'Unit: ${part.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: IconButton(
          key: Key('delete_part_${part.id}'),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete',
        ),
      ),
    );
  }
}

class _EmptyPartsView extends StatelessWidget {
  const _EmptyPartsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No parts found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a part to see it here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load parts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('retry_parts_button'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
