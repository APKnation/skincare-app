import 'package:flutter/material.dart';

class ExpandableSection extends StatefulWidget {
  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry padding;

  const ExpandableSection({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: widget.header,
            trailing: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: widget.padding,
              child: widget.content,
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
