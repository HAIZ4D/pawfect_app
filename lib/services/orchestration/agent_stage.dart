import 'package:flutter/foundation.dart';

/// Lifecycle of a single agent in an orchestrated AI pipeline.
///
/// The order matters — the UI uses `index >= currentRunning` to decide
/// which stages to show as upcoming.
enum AgentStatus { pending, running, completed, failed }

/// One stage in an orchestration. Renderable in the loading UI and
/// updated by the orchestrator as it walks the pipeline.
@immutable
class AgentStage {
  final String key;
  final String title;
  final String subtitle;
  final AgentStatus status;
  final String? errorMessage;

  const AgentStage({
    required this.key,
    required this.title,
    required this.subtitle,
    this.status = AgentStatus.pending,
    this.errorMessage,
  });

  AgentStage copyWith({
    AgentStatus? status,
    String? errorMessage,
  }) {
    return AgentStage(
      key: key,
      title: title,
      subtitle: subtitle,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Snapshot of the entire pipeline at one moment. The UI subscribes to
/// a [ValueNotifier] of this shape and rebuilds on every change.
@immutable
class OrchestrationProgress {
  final List<AgentStage> stages;
  final int activeIndex;

  const OrchestrationProgress({
    required this.stages,
    required this.activeIndex,
  });

  static const OrchestrationProgress empty = OrchestrationProgress(
    stages: [],
    activeIndex: -1,
  );

  OrchestrationProgress markRunning(int index) {
    final next = [
      for (var i = 0; i < stages.length; i++)
        if (i == index)
          stages[i].copyWith(status: AgentStatus.running)
        else
          stages[i],
    ];
    return OrchestrationProgress(stages: next, activeIndex: index);
  }

  OrchestrationProgress markCompleted(int index) {
    final next = [
      for (var i = 0; i < stages.length; i++)
        if (i == index)
          stages[i].copyWith(status: AgentStatus.completed)
        else
          stages[i],
    ];
    return OrchestrationProgress(stages: next, activeIndex: activeIndex);
  }

  OrchestrationProgress markFailed(int index, String reason) {
    final next = [
      for (var i = 0; i < stages.length; i++)
        if (i == index)
          stages[i].copyWith(
            status: AgentStatus.failed,
            errorMessage: reason,
          )
        else
          stages[i],
    ];
    return OrchestrationProgress(stages: next, activeIndex: activeIndex);
  }
}
