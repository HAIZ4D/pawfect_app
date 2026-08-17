import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../../services/orchestration/agent_stage.dart';

/// Editorial loading screen that renders the live state of an
/// orchestrated AI pipeline. Listens to a [ValueNotifier] of
/// [OrchestrationProgress] and redraws as each stage transitions
/// pending → running → completed (or failed).
///
/// Designed as a drop-in replacement for `AILoadingAnimation` on the
/// orchestrated assessment screens. Sits above `LiquidBackground`.
class AgentProgressView extends StatelessWidget {
  final ValueNotifier<OrchestrationProgress> progress;
  final String title;
  final String subtitle;
  final String italicAccent;

  const AgentProgressView({
    super.key,
    required this.progress,
    this.title = 'Multi-agent analysis',
    this.subtitle = 'Five agents reviewing the case in parallel.',
    this.italicAccent = 'Reasoning, not guessing.',
  });

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ValueListenableBuilder<OrchestrationProgress>(
      valueListenable: progress,
      builder: (context, value, _) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, topInset + 132, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(value),
              const SizedBox(height: 28),
              const _Ornament(),
              const SizedBox(height: 24),
              ...List.generate(value.stages.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StageTile(
                    stage: value.stages[i],
                    index: i,
                    isLast: i == value.stages.length - 1,
                  ),
                );
              }),
              const SizedBox(height: 24),
              _buildFooter(value),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────── Header ──────────────────────────────
  Widget _buildHeader(OrchestrationProgress value) {
    final completed = value.stages
        .where((s) => s.status == AgentStatus.completed)
        .length;
    final total = value.stages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 18, height: 1, color: _hairline),
            const SizedBox(width: 12),
            Text(
              '${completed.toString().padLeft(2, "0")} / ${total.toString().padLeft(2, "0")}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _inkSoft,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Reading the case.',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: _ink,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          italicAccent,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: PawfectColors.pawfectOrange,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: _inkSoft.withOpacity(0.92),
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Footer ──────────────────────────────
  Widget _buildFooter(OrchestrationProgress value) {
    final hasFailures = value.stages.any((s) => s.status == AgentStatus.failed);
    final allDone = value.stages.isNotEmpty &&
        value.stages.every((s) => s.status == AgentStatus.completed);

    String message;
    if (hasFailures) {
      message = 'One stage hit an issue. The pipeline will finish what it can.';
    } else if (allDone) {
      message = 'All agents agreed. Finalising the report.';
    } else {
      message = 'Each agent has one job. Less guessing, more grounded answers.';
    }

    return Center(
      child: Column(
        children: [
          Container(width: 36, height: 1, color: _hairline),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: _inkSoft.withOpacity(0.85),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Stage tile ──────────────────────────
class _StageTile extends StatelessWidget {
  final AgentStage stage;
  final int index;
  final bool isLast;

  const _StageTile({
    required this.stage,
    required this.index,
    required this.isLast,
  });

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);
  static const Color _hairline = Color(0x14000000);
  static const Color _low = Color(0xFF2E8A68);
  static const Color _emergency = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isRunning = stage.status == AgentStatus.running;
    final isDone = stage.status == AgentStatus.completed;
    final isFailed = stage.status == AgentStatus.failed;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRunning
              ? [Colors.white, const Color(0xFFFFF1D6)]
              : const [Colors.white, Color(0xFFFFF6E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning
              ? PawfectColors.pawfectOrange.withOpacity(0.45)
              : Colors.white.withOpacity(0.88),
          width: isRunning ? 1.4 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isRunning
                ? PawfectColors.pawfectOrange.withOpacity(0.18)
                : const Color(0x10000000),
            blurRadius: isRunning ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusBadge(
            isRunning: isRunning,
            isDone: isDone,
            isFailed: isFailed,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: PawfectColors.pawfectOrange,
                        letterSpacing: 0.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 14, height: 1, color: _hairline),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        stage.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isFailed
                      ? (stage.errorMessage ?? stage.subtitle)
                      : stage.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: isFailed
                        ? _emergency
                        : _inkSoft.withOpacity(0.92),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isRunning,
    required bool isDone,
    required bool isFailed,
  }) {
    if (isFailed) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _emergency.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _emergency.withOpacity(0.32),
            width: 1.2,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: _emergency,
          size: 18,
        ),
      );
    }
    if (isDone) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _low.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _low.withOpacity(0.32),
            width: 1.2,
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: _low,
          size: 18,
        ),
      );
    }
    if (isRunning) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: PawfectColors.pawfectOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: PawfectColors.pawfectOrange.withOpacity(0.32),
            width: 1.2,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                PawfectColors.pawfectOrange,
              ),
            ),
          ),
        ),
      );
    }
    // Pending
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _hairline, width: 1.2),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _inkSoft.withOpacity(0.45),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Ornament ───────────────────────────
class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 1,
            color: PawfectColors.pawfectOrange.withOpacity(0.35),
          ),
          const SizedBox(width: 14),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: PawfectColors.pawfectOrange,
                width: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 56,
            height: 1,
            color: PawfectColors.pawfectOrange.withOpacity(0.35),
          ),
        ],
      ),
    );
  }
}
