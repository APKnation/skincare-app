import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/recommendation_engine.dart';
import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/recommendation.dart';
import '../../widgets/advanced_card.dart';
import '../product/product_details_page.dart';
import 'assessment_page.dart';

class ForYouPage extends StatelessWidget {
  final Store store;

  const ForYouPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    final profile = store.skinProfile;
    final recommendations = profile == null
        ? const <Recommendation>[]
        : RecommendationEngine.rank(profile, store.approvedProducts);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skin Routine'),
            Text('Personalized routine & skin-matched cosmetics',
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.spa_outlined,
                          size: 56, color: scheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text('Tell Us About Your Skin',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Answer 4 quick questions about your skin type, concerns and sensitivities to get personalized routine suggestions formulated for your skin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => AssessmentPage(store: store))),
                      icon: const Icon(Icons.spa_outlined, size: 18),
                      label: const Text('Start Skin Assessment'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              children: [
                // Skin Profile Card
                AdvancedCard(
                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${profile.skinType.label} Skin Profile',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 14.5),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Active',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.concerns.map((c) => c.label).join(', '),
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Updated ${formatDate(profile.updatedAt)} · Tap pencil icon to retake',
                              style: TextStyle(
                                  fontSize: 10.5, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Disclaimer note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Matches product ingredients to your skin quiz. Cosmetic guidance, not medical diagnosis.',
                          style: TextStyle(
                              fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                if (recommendations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No confident matches yet — try broadening your concerns.'),
                    ),
                  ),
                for (final r in recommendations) _tile(context, r),
              ],
            ),
    );
  }

  Widget _tile(BuildContext context, Recommendation r) {
    final p = r.product;
    final scheme = Theme.of(context).colorScheme;

    return AdvancedCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProductDetailsPage(store: store, product: p))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 12, color: scheme.primary),
                          const SizedBox(width: 3),
                          Text(
                            'Personalized Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    Text(
                      '${p.brand} · ${p.shopName}',
                      style: TextStyle(
                          fontSize: 11.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatTZS(p.priceTZS),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Why recommended reasons
          _block(context, Icons.check_circle_rounded, 'Why Recommended',
              r.reasons, Colors.green.shade700),

          // Precautions if any
          if (r.precautions.isNotEmpty)
            _block(context, Icons.warning_amber_rounded, 'Safety Precautions',
                r.precautions, Colors.amber.shade900),

          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final error = await store.addToCart(p.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(error ?? '${p.name} added to cart')));
                },
                icon: const Icon(Icons.add_shopping_cart, size: 14),
                label: const Text('Add to cart', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, IconData icon, String title,
          List<String> items, Color accent) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
            for (final item in items.take(3))
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 11)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
