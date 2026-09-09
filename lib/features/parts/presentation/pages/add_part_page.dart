import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/part.dart';
import '../../domain/use_cases/add_part.dart';

class AddPartPage extends StatefulWidget {
  AddPartPage({super.key, AddPart? addPart})
    : _addPart = addPart ?? ServiceLocator.instance.addPart;

  final AddPart _addPart;

  @override
  State<AddPartPage> createState() => _AddPartPageState();
}

class _AddPartPageState extends State<AddPartPage> {
  final _formKey = GlobalKey<FormState>();

  final _partCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _specificationController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _unitController = TextEditingController(text: 'EA');

  bool _isSaving = false;

  @override
  void dispose() {
    _partCodeController.dispose();
    _nameController.dispose();
    _specificationController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final part = Part(
        partCode: _partCodeController.text.trim(),
        name: _nameController.text.trim(),
        specification: _specificationController.text.trim().isEmpty
            ? null
            : _specificationController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        unit: _unitController.text.trim(),
      );

      await widget._addPart(part);

      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.partAddedSuccessfully)));

      _formKey.currentState!.reset();

      _partCodeController.clear();
      _nameController.clear();
      _specificationController.clear();
      _barcodeController.clear();
      _unitController.text = 'EA';
    } catch (error) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToAddPart(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addPart)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: const Key('part_code_field'),
              controller: _partCodeController,
              decoration: InputDecoration(
                labelText: l10n.partCode,
                hintText: l10n.enterPartCode,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.partCodeRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('name_field'),
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                hintText: l10n.enterPartName,
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.nameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('specification_field'),
              controller: _specificationController,
              decoration: InputDecoration(
                labelText: l10n.specification,
                hintText: l10n.enterSpecification,
              ),
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('barcode_field'),
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: l10n.barcode,
                hintText: l10n.enterBarcode,
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('unit_field'),
              controller: _unitController,
              decoration: InputDecoration(
                labelText: l10n.unit,
                hintText: l10n.enterUnit,
              ),
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.unitRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const Key('add_part_button'),
                onPressed: _isSaving ? null : _submitForm,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isSaving ? l10n.saving : l10n.addPart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
