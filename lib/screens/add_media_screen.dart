import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/points_data.dart';
import '../models/media_entry.dart';
import '../state/entries_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  RootOption? _root;
  String? _level;
  HomeSpecification? _specification;
  PointOption? _selectedRange;
  PointOption? _selectedItem;
  final TextEditingController _acresController = TextEditingController();
  bool _saving = false;

  bool get _isReady {
    final root = _root;
    if (root == null) return false;
    if (root.isStandalone) return true;
    if (root.label == 'New Homes Community Splat') {
      final acres = _acresValue;
      return acres != null && acres > 0;
    }
    if (root.label == 'Homes') {
      return _level != null && _specification != null && _selectedRange != null;
    }
    return _selectedItem != null;
  }

  double? get _selectedPoints {
    final root = _root;
    if (root == null) return null;
    if (root.isStandalone) return root.points;
    if (root.label == 'New Homes Community Splat') {
      final acres = _acresValue;
      return acres == null ? null : acres * 0.005;
    }
    if (root.label == 'Homes') return _selectedRange?.points;
    return _selectedItem?.points;
  }

  String? get _sqftRange =>
      _root?.label == 'Homes' ? _selectedRange?.label : null;

  String? get _acres {
    if (_root?.label != 'New Homes Community Splat') return null;
    final acres = _acresController.text.trim();
    return acres.isEmpty ? null : acres;
  }

  double? get _acresValue {
    final acres = double.tryParse(_acresController.text.trim());
    return acres != null && acres.isFinite ? acres : null;
  }

  String? get _entryLabel {
    final root = _root;
    if (root == null) return null;
    if (root.isStandalone) return root.label;
    if (root.label == 'New Homes Community Splat') return root.label;
    if (root.label == 'Homes') {
      if (_level == null || _specification == null) return null;
      return 'Homes – $_level – ${_specification!.label}';
    }
    if (_selectedItem == null) return null;
    return '${root.label} – ${_selectedItem!.label}';
  }

  @override
  void dispose() {
    _acresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Media')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const _StepHeading('1', 'What did you capture?'),
                      const SizedBox(height: 8),
                      for (final option in rootOptions) ...[
                        _rootCard(option),
                        if (_root == option) ...[
                          const SizedBox(height: 8),
                          _qualifiedSection(option),
                        ],
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isReady && !_saving ? _submit : null,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? AppTheme.accent.withValues(alpha: 0.35)
                              : AppTheme.accent,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? Colors.white.withValues(alpha: 0.65)
                              : Colors.white,
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PointOption> get _currentItems {
    if (_root?.label == 'Media Shoots') return mediaShootOptions;
    if (_root?.label == 'Neighborhood') return neighborhoodOptions;
    return const [];
  }

  List<Widget> _qualifiedFieldsFor(RootOption option) {
    if (option.label == 'New Homes Community Splat') {
      return [
        _fieldLabel('Acres'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _acresController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter number of acres',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ];
    }

    if (option.label == 'Homes') {
      return [
        _fieldLabel('Level'),
        for (final level in homeLevels) ...[
          _choiceCard(
            title: level.label,
            selected: _level == level.label,
            onTap: () => setState(() {
              _level = level.label;
              _specification = null;
              _selectedRange = null;
            }),
          ),
          if (_level == level.label)
            _nestedSection([
              _fieldLabel('Specification'),
              for (final specification in level.specifications) ...[
                _choiceCard(
                  title: specification.label,
                  selected: _specification == specification,
                  onTap: () => setState(() {
                    _specification = specification;
                    _selectedRange = null;
                  }),
                ),
                if (_specification == specification)
                  _nestedSection([
                    _fieldLabel('Sq Ft Range'),
                    ...specification.ranges.map(
                      (range) => _choiceCard(
                        title:
                            '${range.label} • ${formatExactPoints(range.points)} pts',
                        selected: _selectedRange == range,
                        onTap: () => setState(() => _selectedRange = range),
                      ),
                    ),
                  ]),
              ],
            ]),
        ],
      ];
    }

    if (option.label == 'Media Shoots' || option.label == 'Neighborhood') {
      return [
        _fieldLabel('Item'),
        ..._currentItems.map(
          (item) => _choiceCard(
            title: '${item.label} • ${formatExactPoints(item.points)} pts',
            selected: _selectedItem == item,
            onTap: () => setState(() => _selectedItem = item),
          ),
        ),
      ];
    }

    return const [];
  }

  Widget _qualifiedSection(RootOption option) {
    return _nestedSection(_qualifiedFieldsFor(option));
  }

  Widget _nestedSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(left: 20, bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.secondary
                .withValues(alpha: 0.7),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _rootCard(RootOption option) {
    final subtitle = option.points == null
        ? null
        : '${formatExactPoints(option.points!)} pts';
    return _choiceCard(
      title: option.label,
      subtitle: subtitle,
      selected: _root == option,
      onTap: () => setState(() {
        if (_root == option) {
          _root = null;
          _level = null;
          _specification = null;
          _selectedRange = null;
          _selectedItem = null;
          _acresController.clear();
          return;
        }
        _root = option;
        _level = null;
        _specification = null;
        _selectedRange = null;
        _selectedItem = null;
        _acresController.clear();
      }),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _choiceCard({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      color: selected
          ? colorScheme.secondary.withValues(alpha: 0.12)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: selected ? colorScheme.secondary : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colorScheme.secondary : colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(color: colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final label = _entryLabel;
    final points = _selectedPoints;
    if (label == null || points == null) return;
    setState(() => _saving = true);
    final timestamp = DateTime.now();
    try {
      await context.read<EntriesProvider>().addEntry(
        MediaEntry.create(
          label: label,
          points: points,
          timestamp: timestamp,
          sqftRange: _sqftRange,
          acres: _acres,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading(this.number, this.title);

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          child: Text(number, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
