import 'enums.dart';

class SkinProfile {
  final String userId;
  final SkinType skinType;
  final Set<SkinConcern> concerns;
  final Set<Sensitivity> sensitivities;
  final Set<SkinConcern> goals;
  final String notes;
  final DateTime updatedAt;

  const SkinProfile({
    required this.userId,
    required this.skinType,
    required this.concerns,
    this.sensitivities = const {},
    this.goals = const {},
    this.notes = '',
    required this.updatedAt,
  });
}
