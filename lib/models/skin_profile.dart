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

  factory SkinProfile.fromJson(String userId, Map<String, Object?> j) =>
      SkinProfile(
        userId: userId,
        skinType: SkinType.values.byName(j['skinType'] as String),
        concerns: _set(j['concerns'] as List),
        sensitivities: _setFlagged(j['sensitivities'] as List),
        goals: _set(j['goals'] as List),
        notes: j['notes'] as String? ?? '',
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'skinType': skinType.name,
        'concerns': concerns.map((e) => e.name).toList(),
        'sensitivities': sensitivities.map((e) => e.name).toList(),
        'goals': goals.map((e) => e.name).toList(),
        'notes': notes,
      };

  static Set<SkinConcern> _set(List<Object?> names) =>
      names.map((n) => SkinConcern.values.byName(n as String)).toSet();

  static Set<Sensitivity> _setFlagged(List<Object?> names) =>
      names.map((n) => Sensitivity.values.byName(n as String)).toSet();
}
