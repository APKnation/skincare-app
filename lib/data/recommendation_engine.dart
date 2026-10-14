import '../models/enums.dart';
import '../models/product.dart';
import '../models/recommendation.dart';
import '../models/skin_profile.dart';

/// Rule-based matcher between a customer's skin profile and verified product
/// data. Deterministic and explainable by design: every score traces back to
/// concrete product attributes. This is cosmetic guidance, never a diagnosis.
class RecommendationEngine {
  static List<Recommendation> rank(
      SkinProfile profile, List<Product> products) {
    final wants = {...profile.concerns, ...profile.goals};
    final results = <Recommendation>[];
    for (final p in products) {
      var score = 0;
      final reasons = <String>[];
      final precautions = <String>[];

      if (p.suitableSkinTypes.contains(profile.skinType)) {
        score += 30;
        reasons.add(
            'Formulated for ${profile.skinType.label.toLowerCase()} skin.');
      } else {
        score -= 20;
        precautions.add(
            'Not listed as suitable for ${profile.skinType.label.toLowerCase()} skin — use with care.');
      }

      final matches = wants.intersection(p.targetsConcerns);
      score += matches.length * 15;
      for (final c in matches) {
        reasons.add('Targets ${c.label.toLowerCase()}.');
      }

      for (final s in profile.sensitivities.intersection(p.containsFlagged)) {
        score -= 25;
        precautions.add(
            'Contains ingredients flagged for ${s.label.toLowerCase()} sensitivity.');
      }

      if (profile.skinType == SkinType.sensitive &&
          p.containsFlagged.intersection({
            Sensitivity.fragrance,
            Sensitivity.essentialOils
          }).isNotEmpty) {
        score -= 15;
        precautions.add(
            'You have sensitive skin: fragranced/essential-oil products are common irritants.');
      }

      if (profile.concerns.contains(SkinConcern.acne) && p.isComedogenic) {
        score -= 25;
        precautions.add('Comedogenic — may clog pores and worsen breakouts.');
      }

      if (wants.contains(SkinConcern.darkSpots) ||
          wants.contains(SkinConcern.aging)) {
        reasons.add('Best paired with daily sun protection for visible results.');
      }

      precautions.addAll(p.warnings.take(2));
      if (p.sideEffects.isNotEmpty) {
        precautions.add('Possible side effects: ${p.sideEffects.first}.');
      }

      if (score >= 10 && p.stock > 0) {
        results.add(Recommendation(
          product: p,
          score: score,
          reasons: reasons.isEmpty
              ? ['Matches your general skincare goals.']
              : reasons,
          precautions: precautions.toSet().toList(),
        ));
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(8).toList(growable: false);
  }
}
