import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/prep_item.dart';

/// Pre-fight prep loadout (max 3). Confirms → consumes inventory + sets pending.
Future<bool> showPrepPickerSheet(
  BuildContext context, {
  required String encounterName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MythDuskColors.deepTeal,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => PrepPickerSheet(encounterName: encounterName),
  );
  return result ?? false;
}

class PrepPickerSheet extends ConsumerStatefulWidget {
  const PrepPickerSheet({super.key, required this.encounterName});

  final String encounterName;

  @override
  ConsumerState<PrepPickerSheet> createState() => _PrepPickerSheetState();
}

class _PrepPickerSheetState extends ConsumerState<PrepPickerSheet> {
  final _selected = <PrepItemId>{};

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Prepare for ${widget.encounterName}',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Optional aids — equip up to ${PrepBalance.maxEquipped}, or enter with none. Spent when battle starts.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final id in PrepItemId.values)
                  _PrepChoiceTile(
                    id: id,
                    count: profile.prepCount(id),
                    selected: _selected.contains(id),
                    canSelect: profile.prepCount(id) > 0 &&
                        (_selected.contains(id) ||
                            _selected.length < PrepBalance.maxEquipped),
                    secondWindBlocked: id == PrepItemId.secondWind &&
                        profile.secondWindUsedDay == _todayKey(),
                    onToggle: () {
                      setState(() {
                        if (_selected.contains(id)) {
                          _selected.remove(id);
                        } else {
                          _selected.add(id);
                        }
                      });
                    },
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    final list = _selected.toList();
                    if (list.isNotEmpty) {
                      final ok =
                          ref.read(profileProvider.notifier).consumePrep(list);
                      if (!ok) return;
                    }
                    ref.read(pendingBossPrepProvider.notifier).state = list;
                    Navigator.of(context).pop(true);
                  },
                  child: Text(
                    _selected.isEmpty
                        ? 'Enter with no prep'
                        : 'Enter with ${_selected.length} prep',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }
}

class _PrepChoiceTile extends StatelessWidget {
  const _PrepChoiceTile({
    required this.id,
    required this.count,
    required this.selected,
    required this.canSelect,
    required this.secondWindBlocked,
    required this.onToggle,
  });

  final PrepItemId id;
  final int count;
  final bool selected;
  final bool canSelect;
  final bool secondWindBlocked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? MythDuskColors.mist
            : MythDuskColors.ink.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: (!canSelect || secondWindBlocked) ? null : onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    id.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.science_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        secondWindBlocked
                            ? 'Already used today'
                            : '${id.blurb} · own $count',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color:
                              secondWindBlocked ? MythDuskColors.ember : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? MythDuskColors.amber : MythDuskColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
