import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/recommendation_engine.dart';
import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/recommendation.dart';
import '../product/product_details_page.dart';
import 'assessment_page.dart';

class ForYouPage extends StatelessWidget {
  final Store store;

  const ForYouPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final profile = store.skinProfile;
    final recommendations = profile == null
        ? const <Recommendation>[]
        : RecommendationEngine.rank(profile, store.approvedProducts);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For You'),
            Text('Matches picked from your skin profile',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: profile == null ? 'Take assessment' : 'Edit assessment',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AssessmentPage(store: store))),
          ),
        ],
      ),
      body: profile == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.face_retouching_natural,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text('Tell us about your skin',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text(
                        'Answer 4 short questions about your skin type, concerns, sensitivities and goals, and we will match verified products to you.'),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  AssessmentPage(store: store))),
                      child: const Text('Start skin assessment'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your skin profile',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text('${profile.skinType.label} skin · '
                            '${profile.concerns.map((c) => c.label).join(', ')}'),
                        Text('Updated ${formatDate(profile.updatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Suggestions match product data to your answers. '
                          'They are cosmetic guidance, not medical advice.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (recommendations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No confident matches yet — try broadening your concerns.'),
                  ),
                for (final r in recommendations) _tile(context, r),
              ],
            ),
    );
  }

  Widget _tile(BuildContext context, Recommendation r) {
    final p = r.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailsPage(store: store, product: p))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p.name,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text(formatTZS(p.priceTZS)),
                ],
              ),
              Text('${p.brand} · ${p.shopName}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              _block(context, Icons.check_circle_outline, 'Why recommended',
                  r.reasons),
              _block(context, Icons.warning_amber_rounded, 'Precautions',
                  r.precautions),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () async {
                    final error = await store.addToCart(p.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? '${p.name} added to cart')));
                  },
                  child: const Text('Add to cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(BuildContext context, IconData icon, String title,
          List<String> items) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(title,
                    style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            for (final item in items.take(4))
              Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: Text(item,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      );
}
