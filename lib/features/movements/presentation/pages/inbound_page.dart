import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';

class InboundPage extends StatefulWidget {
  const InboundPage({super.key});

  @override
  State<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends State<InboundPage> {
  final _partNoController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();

  String? _boxNo;
  String? _boxNoError;
  bool _isGeneratingBoxNo = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBoxNo();
  }

  @override
  void dispose() {
    _partNoController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadBoxNo() async {
    if (mounted) {
      setState(() {
        _isGeneratingBoxNo = true;
        _boxNoError = null;
      });
    }

    try {
      final boxNo = await ServiceLocator.instance.boxNumberGenerator.peek();

      if (!mounted) {
        return;
      }

      setState(() {
        _boxNo = boxNo;
        _boxNoError = null;
        _isGeneratingBoxNo = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _boxNo = null;
        _boxNoError = error.toString();
        _isGeneratingBoxNo = false;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final partNo = _partNoController.text.trim();
    final quantityText = _quantityController.text.trim();
    final location = _locationController.text.trim();

    if (partNo.isEmpty) {
      _showError('Please enter part number.');
      return;
    }

    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      _showError('Please enter a valid quantity.');
      return;
    }

    if (location.isEmpty) {
      _showError('Please enter location.');
      return;
    }

    if (_boxNo == null) {
      _showError('BOX NO is not available.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = await ServiceLocator.instance.saveInboundTransaction(
        partNo: partNo,
        quantity: quantity,
        location: location,
      );

      unawaited(_syncPendingOperations());

      if (!mounted) {
        return;
      }

      _partNoController.clear();
      _quantityController.clear();
      _locationController.clear();

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved ${transaction.boxNo}')));

      await _loadBoxNo();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showError(error.toString());
    }
  }

  Future<void> _syncPendingOperations() async {
    try {
      await ServiceLocator.instance.syncEngine.syncPendingOperations();
    } catch (_) {
      // Local save has already succeeded.
      // Pending operation will be retried later.
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiving)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.boxNo, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: _buildBoxNoContent(context),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _partNoController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.partCode,
                  hintText: l10n.enterPartCode,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _quantityController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                  hintText: l10n.enterQuantity,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: l10n.location,
                  hintText: l10n.enterLocation,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxNoContent(BuildContext context) {
    if (_isGeneratingBoxNo) {
      return const SizedBox(
        height: 24,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_boxNoError != null) {
      return Text(
        'Failed to generate BOX NO.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    return Text(_boxNo ?? '—', style: Theme.of(context).textTheme.bodyLarge);
  }
}
