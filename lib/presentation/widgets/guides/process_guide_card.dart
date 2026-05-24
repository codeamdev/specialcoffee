import 'package:flutter/material.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/guides/process_guide_content.dart';

// ── Process Type Guide Card ────────────────────────────────────────────────
// Shows the full overview of a process type: description, steps, key params,
// tips, and warning. Used on lot creation and at start of fermentation.

class ProcessTypeGuideCard extends StatefulWidget {
  const ProcessTypeGuideCard({super.key, required this.processType});

  final String processType;

  @override
  State<ProcessTypeGuideCard> createState() => _ProcessTypeGuideCardState();
}

class _ProcessTypeGuideCardState extends State<ProcessTypeGuideCard> {
  bool _stepsExpanded  = false;
  bool _paramsExpanded = false;
  bool _tipsExpanded   = false;

  @override
  void didUpdateWidget(ProcessTypeGuideCard old) {
    super.didUpdateWidget(old);
    if (old.processType != widget.processType) {
      _stepsExpanded  = false;
      _paramsExpanded = false;
      _tipsExpanded   = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ProcessGuideContent.processTypes[widget.processType];
    if (info == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppColors.caramel.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Row(children: [
              Text(info.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.schedule_outlined,
                          size: 12, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          info.duration,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Guía',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),

          // ── Description ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Text(info.description, style: AppTextStyles.bodyMedium),
          ),

          const SizedBox(height: 10),

          // ── Steps ─────────────────────────────────────────────────────────
          _ExpandableSection(
            title: 'Paso a paso',
            icon: Icons.format_list_numbered_rounded,
            count: info.steps.length,
            expanded: _stepsExpanded,
            onToggle: () => setState(() => _stepsExpanded = !_stepsExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: info.steps.indexed.map((e) {
                final (i, step) = e;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.caramel,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(step, style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Key Params ────────────────────────────────────────────────────
          _ExpandableSection(
            title: 'Parámetros clave',
            icon: Icons.tune_rounded,
            count: info.keyParams.length,
            expanded: _paramsExpanded,
            onToggle: () => setState(() => _paramsExpanded = !_paramsExpanded),
            child: Column(
              children: info.keyParams.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(p.name,
                            style: AppTextStyles.labelMedium),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          p.value,
                          style: AppTextStyles.numericSmall.copyWith(
                            color: AppColors.caramel,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          p.note,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Tips ──────────────────────────────────────────────────────────
          if (info.tips.isNotEmpty)
            _ExpandableSection(
              title: 'Consejos',
              icon: Icons.lightbulb_outline_rounded,
              count: info.tips.length,
              expanded: _tipsExpanded,
              onToggle: () => setState(() => _tipsExpanded = !_tipsExpanded),
              child: Column(
                children: info.tips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(tip, style: AppTextStyles.bodyMedium),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Warning ───────────────────────────────────────────────────────
          if (info.warning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info.warning,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Fermentation Phase Card ────────────────────────────────────────────────
// Shows the current fermentation phase guide based on the latest pH reading.

class FermentationPhaseCard extends StatefulWidget {
  const FermentationPhaseCard({
    super.key,
    required this.ph,
    required this.hoursElapsed,
  });

  final double ph;
  final double hoursElapsed;

  @override
  State<FermentationPhaseCard> createState() => _FermentationPhaseCardState();
}

class _FermentationPhaseCardState extends State<FermentationPhaseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final phase = ProcessGuideContent.currentFermentationPhase(widget.ph);
    if (phase == null) return const SizedBox.shrink();

    final hint   = ProcessGuideContent.nextFermentationReadingHint(
        widget.ph, widget.hoursElapsed);
    final color  = _phaseColor(phase.icon);
    final bgColor = color.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible) ───────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(children: [
                Text(phase.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fase: ${phase.name}',
                        style: AppTextStyles.labelLarge.copyWith(color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: color.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'pH ${widget.ph.toStringAsFixed(2)}',
                    style: AppTextStyles.numericSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: color,
                ),
              ]),
            ),
          ),

          // ── Expandable body ───────────────────────────────────────────────
          if (_expanded) ...[
            // What's happening
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.science_outlined,
                    label: '¿Qué está pasando?',
                  ),
                  const SizedBox(height: 6),
                  Text(phase.whatHappens, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // What to do
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.task_alt_rounded,
                    label: '¿Qué hacer ahora?',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  ...phase.whatToDo.map(
                    (step) => _BulletItem(text: step, color: color),
                  ),
                ],
              ),
            ),

            // Warning sign
            if (phase.warningSign.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phase.warningSign,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Color _phaseColor(String icon) => switch (icon) {
        '🟢' => AppColors.info,
        '🟡' => AppColors.warning,
        '✅' => AppColors.success,
        '🔴' => AppColors.error,
        _    => AppColors.caramel,
      };
}

// ── Drying Phase Card ──────────────────────────────────────────────────────
// Shows the current drying phase guide based on the latest moisture reading.

class DryingPhaseCard extends StatefulWidget {
  const DryingPhaseCard({super.key, required this.moisturePct});

  final double moisturePct;

  @override
  State<DryingPhaseCard> createState() => _DryingPhaseCardState();
}

class _DryingPhaseCardState extends State<DryingPhaseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final phase = ProcessGuideContent.currentDryingPhase(widget.moisturePct);
    if (phase == null) return const SizedBox.shrink();

    final color  = _phaseColor(widget.moisturePct);
    final bgColor = color.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible) ───────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(14),
                  bottom: _expanded ? Radius.zero : const Radius.circular(14),
                ),
              ),
              child: Row(children: [
                Text(phase.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        phase.name,
                        style: AppTextStyles.labelLarge.copyWith(color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Próxima lectura: ${phase.nextReadingIn}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: color.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.moisturePct.toStringAsFixed(1)}%',
                    style: AppTextStyles.numericSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: color,
                ),
              ]),
            ),
          ),

          // ── Expandable body ───────────────────────────────────────────────
          if (_expanded) ...[
            // What's happening
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.wb_sunny_outlined,
                    label: '¿Qué está pasando?',
                  ),
                  const SizedBox(height: 6),
                  Text(phase.whatHappens, style: AppTextStyles.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // What to do
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(
                    icon: Icons.task_alt_rounded,
                    label: '¿Qué hacer ahora?',
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  ...phase.whatToDo.map(
                    (step) => _BulletItem(text: step, color: color),
                  ),
                ],
              ),
            ),

            // Warning
            if (phase.warning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          phase.warning,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Color _phaseColor(double moisture) {
    if (moisture >= 10.5 && moisture <= 12.0) return AppColors.success;
    if (moisture < 10.5) return AppColors.error;
    if (moisture < 20) return AppColors.warning;
    if (moisture < 35) return AppColors.caramel;
    return AppColors.info;
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.count,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String   title;
  final IconData icon;
  final int      count;
  final bool     expanded;
  final VoidCallback onToggle;
  final Widget   child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(children: [
                Icon(icon, size: 16, color: AppColors.caramel),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.labelMedium),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
              ]),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: child,
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.color = AppColors.caramel,
  });

  final IconData icon;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 6),
      Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    ]);
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.text, required this.color});

  final String text;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
