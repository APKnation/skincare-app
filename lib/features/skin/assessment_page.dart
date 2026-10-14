import 'package:flutter/material.dart';

import '../../data/store.dart';
import '../../models/enums.dart';
import '../../models/skin_profile.dart';

class AssessmentPage extends StatefulWidget {
  final Store store;

  const AssessmentPage({super.key, required this.store});

  @override
  State<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends State<AssessmentPage> {
  SkinType? _skinType;
  final Set<SkinConcern> _concerns = {};
  final Set<SkinConcern> _goals = {};
  final Set<Sensitivity> _sensitivities = {};
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = widget.store.skinProfile;
    if (existing != null) {
      _skinType = existing.skinType;
      _concerns.addAll(existing.concerns);
      _goals.addAll(existing.goals);
      _sensitivities.addAll(existing.sensitivities);
      _notes.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = widget.store.currentUser?.id;
    if (userId == null || _skinType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please choose your skin type.')));
      return;
    }
    if (_concerns.isEmpty && _goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pick at least one concern or goal.')));
      return;
    }
    final error = await widget.store.saveSkinProfile(SkinProfile(
      userId: userId,
      skinType: _skinType!,
      concerns: {..._concerns},
      goals: {..._goals},
      sensitivities: {..._sensitivities},
      notes: _notes.text,
      updatedAt: DateTime.now(),
    ));
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _chips<T extends Enum>(
          {required List<T> values,
          required String Function(T) label,
          required Set<T> selected,
          bool allowDeselect = true}) =>
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
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skin assessment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1. Your skin type',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          RadioGroup<SkinType>(
            groupValue: _skinType,
            onChanged: (v) => setState(() => _skinType = v),
            child: Column(
              children: [
                for (final t in SkinType.values)
                  RadioListTile<SkinType>(
                    title: Text(t.label),
                    value: t,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('2. Skin concerns',
              style: Theme.of(context).textTheme.titleMedium),
          Text('What bothers you most about your skin right now.'),
          const SizedBox(height: 8),
          _chips<SkinConcern>(
              values: SkinConcern.values,
              label: (c) => c.label,
              selected: _concerns),
          const SizedBox(height: 16),
          Text('3. Sensitivities',
              style: Theme.of(context).textTheme.titleMedium),
          Text('Ingredients that usually irritate your skin.'),
          const SizedBox(height: 8),
          _chips<Sensitivity>(
              values: Sensitivity.values,
              label: (s) => s.label,
              selected: _sensitivities),
          const SizedBox(height: 16),
          Text('4. Your skincare goals',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _chips<SkinConcern>(
              values: SkinConcern.values,
              label: (c) => c.label,
              selected: _goals),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. reacts to strong scents, stays indoors mostly'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save assessment')),
          const SizedBox(height: 12),
          Text(
            'This assessment guides product matching only. It is not a medical '
            'diagnosis. For persistent rashes, pain or sudden changes, see a '
            'licensed clinician.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
