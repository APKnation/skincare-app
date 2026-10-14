import 'package:flutter_test/flutter_test.dart';
import 'package:ngozi_yangu/data/recommendation_engine.dart';
import 'package:ngozi_yangu/data/seed_data.dart';
import 'package:ngozi_yangu/models/enums.dart';
import 'package:ngozi_yangu/models/skin_profile.dart';

void main() {
  group('RecommendationEngine', () {
    test('oily acne-prone skin prefers niacinamide, avoids coconut oil', () {
      final profile = SkinProfile(
        userId: 'u1',
        skinType: SkinType.oily,
        concerns: {SkinConcern.acne, SkinConcern.oiliness},
        updatedAt: DateTime(2026, 10),
      );
      final ranked =
          RecommendationEngine.rank(profile, seedProducts);
      final ids = ranked.map((r) => r.product.id).toList();
      expect(ids.contains('p-niacinamide'), isTrue);
      expect(ids.indexOf('p-niacinamide'),
          lessThan(ids.contains('p-coconut') ? ids.indexOf('p-coconut') : 99));
      expect(ids.contains('p-coconut'), isFalse,
          reason: 'comedogenic coconut oil should not surface for acne skin');
    });

    test('fragrance sensitivity produces precautions on flagged products',
        () {
      final profile = SkinProfile(
        userId: 'u1',
        skinType: SkinType.sensitive,
        concerns: {SkinConcern.dryness},
        sensitivities: {Sensitivity.fragrance},
        updatedAt: DateTime(2026, 10),
      );
      final ranked = RecommendationEngine.rank(profile, seedProducts);
      for (final r in ranked) {
        if (r.product.containsFlagged.contains(Sensitivity.fragrance)) {
          expect(
              r.precautions.any((p) => p.toLowerCase().contains('fragrance')),
              isTrue,
              reason: '${r.product.name} must warn about fragrance');
        }
      }
    });

    test('every recommendation explains itself', () {
      final profile = SkinProfile(
        userId: 'u1',
        skinType: SkinType.dry,
        concerns: {SkinConcern.dryness},
        updatedAt: DateTime(2026, 10),
      );
      final ranked = RecommendationEngine.rank(profile, seedProducts);
      expect(ranked, isNotEmpty);
      for (final r in ranked) {
        expect(r.reasons, isNotEmpty);
      }
    });
  });
}
