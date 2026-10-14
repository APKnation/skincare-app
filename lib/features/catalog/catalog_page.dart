import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_logo.dart';
import '../product/compare_page.dart';
import '../product/product_details_page.dart';

class CatalogPage extends StatefulWidget {
  final Store store;

  const CatalogPage({super.key, required this.store});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _search = TextEditingController();
  ProductCategory? _category;
  SkinType? _skinType;
  String? _location;
  int _maxPrice = 50000;
  _Sort _sort = _Sort.newest;
  final Set<String> _compare = {};

  Store get store => widget.store;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _search.text.trim().toLowerCase();
    var list = store.approvedProducts.where((p) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.brand.toLowerCase().contains(q) &&
          !p.shopName.toLowerCase().contains(q) &&
          !p.ingredients.join(' ').toLowerCase().contains(q)) {
        return false;
      }
      if (_category != null && p.category != _category) return false;
      if (_skinType != null && !p.suitableSkinTypes.contains(_skinType)) {
        return false;
      }
      if (_location != null && p.shopLocation != _location) return false;
      if (p.priceTZS > _maxPrice) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.priceAsc:
        list.sort((a, b) => a.priceTZS.compareTo(b.priceTZS));
      case _Sort.priceDesc:
        list.sort((a, b) => b.priceTZS.compareTo(a.priceTZS));
      case _Sort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  void _toggleCompare(String id) {
    setState(() {
      if (_compare.contains(id)) {
        _compare.remove(id);
      } else if (_compare.length < 3) {
        _compare.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compare up to 3 products.')));
      }
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Skin type', style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Any'),
                    selected: _skinType == null,
                    onSelected: (_) => setSheet(() =>
                        setState(() => _skinType = null)),
                  ),
                  for (final t in SkinType.values)
                    ChoiceChip(
                      label: Text(t.label),
                      selected: _skinType == t,
                      onSelected: (_) =>
                          setSheet(() => setState(() => _skinType = t)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Seller location',
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Anywhere'),
                    selected: _location == null,
                    onSelected: (_) => setSheet(() =>
                        setState(() => _location = null)),
                  ),
                  for (final l in store.shopLocations)
                    ChoiceChip(
                      label: Text(l, style: const TextStyle(fontSize: 12)),
                      selected: _location == l,
                      onSelected: (_) =>
                          setSheet(() => setState(() => _location = l)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Max price: ${(_maxPrice / 1000).round()}k TZS',
                  style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: _maxPrice.toDouble(),
                min: 5000,
                max: 50000,
                divisions: 9,
                onChanged: (v) =>
                    setSheet(() => setState(() => _maxPrice = v.round())),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final products = _filtered;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sura Yangu',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    'Karibu, ${store.currentUser?.name.split(' ').first ?? 'duka'} — find your match',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search products, brands, ingredients…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _openFilterSheet,
                      tooltip: 'Filters',
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _category == null,
                        onSelected: (_) =>
                            setState(() => _category = null),
                      ),
                    ),
                    for (final c in ProductCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.label),
                          selected: _category == c,
                          onSelected: (_) => setState(
                              () => _category = _category == c ? null : c),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: DropdownButton<_Sort>(
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                              value: _Sort.newest, child: Text('Newest')),
                          DropdownMenuItem(
                              value: _Sort.priceAsc, child: Text('Price ↑')),
                          DropdownMenuItem(
                              value: _Sort.priceDesc, child: Text('Price ↓')),
                          DropdownMenuItem(
                              value: _Sort.name, child: Text('Name')),
                        ],
                        onChanged: (v) => setState(() => _sort = v!),
                      ),
                    ),
                  ),
                  if (_compare.length >= 2)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.compare_arrows),
                        label: Text('Compare ${_compare.length}'),
                        onPressed: () {
                          final items = _compare
                              .map((id) => store.productById(id)!)
                              .toList();
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ComparePage(store: store, products: items)));
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products match your filters.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailsPage(store: store, product: p))),
                  child: ProductCard(
                    product: p,
                    onTap: () {},
                    selectedForCompare: _compare.contains(p.id),
                    onToggleCompare: () => _toggleCompare(p.id),
                  ),
                );
              },
            ),
    );
  }
}

enum _Sort { newest, priceAsc, priceDesc, name }
