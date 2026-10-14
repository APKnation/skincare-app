import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/product.dart';

const _allowedImageExts = {'jpg', 'jpeg', 'png', 'webp', 'gif'};

class ProductFormPage extends StatefulWidget {
  final Store store;
  final Product? existing;

  const ProductFormPage({super.key, required this.store, this.existing});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _brand = TextEditingController(text: widget.existing?.brand);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _price = TextEditingController(
      text: widget.existing?.priceTZS.toString() ?? '');
  late final _stock =
      TextEditingController(text: widget.existing?.stock.toString() ?? '1');
  late final _ingredients = TextEditingController(
      text: widget.existing?.ingredients.join(', ') ?? '');
  late final _usage =
      TextEditingController(text: widget.existing?.usageInstructions ?? '');
  late final _sideEffects =
      TextEditingController(text: widget.existing?.sideEffects.join('\n') ?? '');
  late final _warnings =
      TextEditingController(text: widget.existing?.warnings.join('\n') ?? '');
  late ProductCategory _category =
      widget.existing?.category ?? ProductCategory.facialOil;
  late final Set<SkinType> _skinTypes = {...?widget.existing?.suitableSkinTypes};
  late final Set<SkinConcern> _concerns = {...?widget.existing?.targetsConcerns};
  late final Set<Sensitivity> _flagged = {...?widget.existing?.containsFlagged};
  late bool _comedogenic = widget.existing?.isComedogenic ?? false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _description,
      _price,
      _stock,
      _ingredients,
      _usage,
      _sideEffects,
      _warnings
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skinTypes.isEmpty) {
      _showError('Select at least one suitable skin type.');
      return;
    }
    if (widget.existing == null && _usage.text.trim().isEmpty) {
      _showError('Usage instructions are required.');
      return;
    }
    final me = widget.store.currentUser!;
    final draft = Product(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category,
      description: _description.text.trim(),
      priceTZS: int.parse(_price.text.trim()),
      ingredients: _split(_ingredients.text),
      suitableSkinTypes: {..._skinTypes},
      targetsConcerns: {..._concerns},
      containsFlagged: {..._flagged},
      isComedogenic: _comedogenic,
      usageInstructions: _usage.text.trim(),
      sideEffects: _split(_sideEffects.text, newline: true),
      warnings: _split(_warnings.text, newline: true),
      stock: int.parse(_stock.text.trim()),
      sellerId: me.id,
      shopName: me.shopName ?? '',
      shopLocation: me.shopLocation ?? '',
      approval: widget.existing?.approval ?? ProductApproval.pending,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    final error = widget.existing == null
        ? await widget.store.addProduct(draft)
        : await widget.store.updateProduct(draft);
    if (error != null) {
      _showError(error);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.existing == null
          ? 'Saved — a product reviewer will check it before it goes live.'
          : 'Product updated.'),
    ));
  }

  static List<String> _split(String value, {bool newline = false}) => value
      .split(newline ? '\n' : ',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  void _showError(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Widget _multiChips<T extends Enum>(
          {required String title,
          required List<T> values,
          required String Function(T) label,
          required Set<T> selected}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                FilterChip(
                  label: Text(label(v)),
                  selected: selected.contains(v),
                  onSelected: (on) => setState(
                      () => on ? selected.add(v) : selected.remove(v)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null
              ? 'New product'
              : 'Edit product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _brand,
                decoration: const InputDecoration(labelText: 'Brand')),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in ProductCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _description,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Write a helpful description (10+ characters)'
                    : null),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                      controller: _price,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Price (TZS)'),
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Numbers only'
                          : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Stock'),
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Numbers only'
                          : null),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
                controller: _ingredients,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Ingredients (comma separated)',
                    helperText:
                        'Full honest list — reviewers validate claims against it'),
                validator: (v) =>
                    (v == null || v.trim().length < 3) ? 'Required' : null),
            const SizedBox(height: 16),
            _multiChips<SkinType>(
                title: 'Suitable skin types',
                values: SkinType.values,
                label: (t) => t.label,
                selected: _skinTypes),
            _multiChips<SkinConcern>(
                title: 'Targets concerns',
                values: SkinConcern.values,
                label: (c) => c.label,
                selected: _concerns),
            _multiChips<Sensitivity>(
                title: 'Contains potential irritants',
                values: Sensitivity.values,
                label: (s) => s.label,
                selected: _flagged),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Comedogenic (may clog pores)'),
              subtitle: const Text(
                  'Check this for oils/butters like coconut or shea'),
              value: _comedogenic,
              onChanged: (v) => setState(() => _comedogenic = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
                controller: _usage,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Usage instructions')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _sideEffects,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Possible side effects (one per line)')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _warnings,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText:
                        'Warnings, incl. excessive use (one per line)')),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: _save, child: const Text('Save product'))),
          ],
        ),
      ),
    );
  }
}
