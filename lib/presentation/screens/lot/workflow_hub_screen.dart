import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:special_coffee/core/constants/workflow_config.dart';
import 'package:special_coffee/core/theme/app_colors.dart';
import 'package:special_coffee/core/theme/app_text_styles.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart';
import 'package:special_coffee/presentation/providers/lot_provider.dart';
import 'package:special_coffee/presentation/providers/workflow_provider.dart';

class WorkflowHubScreen extends ConsumerWidget {
  const WorkflowHubScreen({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotAsync      = ref.watch(lotByIdProvider(lotId));
    final workflowAsync = ref.watch(workflowProvider(lotId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Seguimiento de lote')),
      body: lotAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => const Center(child: Text('Error al cargar el lote')),
        data:    (lot) {
          if (lot == null) return const Center(child: Text('Lote no encontrado'));
          final stages = WorkflowConfig.stagesFor(lot.processType);
          return workflowAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (_, __) => const Center(child: Text('Error al cargar el workflow')),
            data:    (wf) => _WorkflowBody(
              lotId:     lotId,
              stages:    stages,
              workflow:  wf,
              processType: lot.processType,
            ),
          );
        },
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _WorkflowBody extends StatelessWidget {
  const _WorkflowBody({
    required this.lotId,
    required this.stages,
    required this.workflow,
    required this.processType,
  });

  final String          lotId;
  final List<String>    stages;
  final WorkflowState   workflow;
  final String          processType;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      children: [
        if (workflow.error != null)
          _ErrorBanner(workflow.error!),
        for (int i = 0; i < stages.length; i++)
          _StageTile(
            lotId:       lotId,
            stage:       stages[i],
            isLast:      i == stages.length - 1,
            processType: processType,
            workflow:    workflow,
          ),
      ],
    );
  }
}

// ── Stage tile ────────────────────────────────────────────────────────────────

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.lotId,
    required this.stage,
    required this.isLast,
    required this.processType,
    required this.workflow,
  });

  final String        lotId;
  final String        stage;
  final bool          isLast;
  final String        processType;
  final WorkflowState workflow;

  @override
  Widget build(BuildContext context) {
    final completed = workflow.completedStages.where((s) => s.stage == stage).firstOrNull;
    final active    = workflow.activeStage?.stage == stage ? workflow.activeStage : null;
    final isCompleted = completed != null;
    final isActive    = active != null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _StageCircle(isCompleted: isCompleted, isActive: isActive),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _StageCard(
                lotId:       lotId,
                stage:       stage,
                processType: processType,
                completed:   completed,
                active:      active,
                workflow:    workflow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stage card ────────────────────────────────────────────────────────────────

class _StageCard extends ConsumerWidget {
  const _StageCard({
    required this.lotId,
    required this.stage,
    required this.processType,
    required this.workflow,
    this.completed,
    this.active,
  });

  final String        lotId;
  final String        stage;
  final String        processType;
  final WorkflowState workflow;
  final LotStageLog?  completed;
  final LotStageLog?  active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = completed != null;
    final isActive    = active != null;
    final label       = WorkflowConfig.stageLabel(stage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.warning.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              const Spacer(),
              if (isActive && active!.isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Vencida ${active!.overdueHours.toStringAsFixed(1)}h',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white, fontSize: 10),
                  ),
                ),
              if (isCompleted)
                Text('✓', style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 4),
          if (isActive)
            _ActiveTimer(active: active!)
          else if (isCompleted)
            Text('Completado', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant))
          else if (!workflow.hasActiveStage)
            _StartButton(
              onStart: () => _startStage(context, ref),
            )
          else
            Text('Pendiente', style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.outlineVariant)),
          if (isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCompleteDialog(context, ref, active!.id),
                child: const Text('Completar etapa'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startStage(BuildContext context, WidgetRef ref) async {
    final expectedH = WorkflowConfig.expectedH(stage, processType);
    await ref.read(workflowProvider(lotId).notifier).startStage(
      stage,
      processType:       processType,
      expectedDurationH: expectedH > 0 ? expectedH : null,
    );
  }

  Future<void> _showCompleteDialog(
      BuildContext context, WidgetRef ref, String logId) async {
    await showDialog<void>(
      context: context,
      builder: (_) => WorkflowCompleteDialog(
        lotId: lotId,
        logId: logId,
        stage: stage,
      ),
    );
  }
}

// ── Active timer ──────────────────────────────────────────────────────────────

class _ActiveTimer extends StatefulWidget {
  const _ActiveTimer({required this.active});

  final LotStageLog active;

  @override
  State<_ActiveTimer> createState() => _ActiveTimerState();
}

class _ActiveTimerState extends State<_ActiveTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed  = widget.active.elapsedHours;
    final expected = widget.active.expectedDurationH;
    final hh       = elapsed.floor();
    final mm       = ((elapsed - hh) * 60).round();
    final label    = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} '
        '${expected != null && expected > 0 ? "/ ${expected.toStringAsFixed(0)}h esperadas" : "transcurridas"}';

    return Text(
      label,
      style: AppTextStyles.bodySmall.copyWith(
        color: widget.active.isOverdue ? AppColors.error : AppColors.caramel,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── Start button ──────────────────────────────────────────────────────────────

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded, size: 18),
        label: const Text('Iniciar etapa'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.aiBlue,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

// ── Stage circle ──────────────────────────────────────────────────────────────

class _StageCircle extends StatelessWidget {
  const _StageCircle({required this.isCompleted, required this.isActive});

  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 28, height: 28,
        decoration: const BoxDecoration(
            color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warning, width: 2),
        ),
        child: Center(
          child: Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(
                color: AppColors.warning, shape: BoxShape.circle),
          ),
        ),
      );
    }
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.outlineVariant, width: 2),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Text(message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
      );
}

// ── Complete Dialog ───────────────────────────────────────────────────────────

class WorkflowCompleteDialog extends ConsumerStatefulWidget {
  const WorkflowCompleteDialog({
    super.key,
    required this.lotId,
    required this.logId,
    required this.stage,
  });

  final String lotId;
  final String logId;
  final String stage;

  @override
  ConsumerState<WorkflowCompleteDialog> createState() =>
      _WorkflowCompleteDialogState();
}

class _WorkflowCompleteDialogState
    extends ConsumerState<WorkflowCompleteDialog> {
  final _phStartC = TextEditingController();
  final _phEndC   = TextEditingController();
  final _tempC    = TextEditingController();
  final _brixC    = TextEditingController();
  final _notesC   = TextEditingController();
  bool  _saving   = false;

  @override
  void dispose() {
    _phStartC.dispose(); _phEndC.dispose();
    _tempC.dispose(); _brixC.dispose(); _notesC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Completar — ${WorkflowConfig.stageLabel(widget.stage)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumField(controller: _phStartC, label: 'pH inicio'),
              const SizedBox(height: 10),
              _NumField(controller: _phEndC,   label: 'pH final'),
              const SizedBox(height: 10),
              _NumField(controller: _tempC,    label: 'Temperatura (°C)'),
              const SizedBox(height: 10),
              _NumField(controller: _brixC,    label: '°Brix'),
              const SizedBox(height: 10),
              TextField(
                controller: _notesC,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar'),
          ),
        ],
      );

  Future<void> _submit() async {
    setState(() => _saving = true);
    await ref.read(workflowProvider(widget.lotId).notifier).completeStage(
      widget.logId,
      phStart:  double.tryParse(_phStartC.text),
      phEnd:    double.tryParse(_phEndC.text),
      tempC:    double.tryParse(_tempC.text),
      brixValue: double.tryParse(_brixC.text),
      notes:    _notesC.text.trim().isEmpty ? null : _notesC.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.controller, required this.label});

  final TextEditingController controller;
  final String                label;

  @override
  Widget build(BuildContext context) => TextField(
        controller:  controller,
        decoration:  InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      );
}
