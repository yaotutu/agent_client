import 'package:agent_client/features/nanobot/domain/nanobot_event.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_media_attachment.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_thread_state.dart';

class NanobotThreadReducer {
  const NanobotThreadReducer._();

  static NanobotThreadState reduce(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    if (event.chatId != null && event.chatId != state.chatId) {
      return state;
    }

    return switch (event.kind) {
      NanobotEventKind.delta => _appendDelta(state, event),
      NanobotEventKind.reasoningDelta => _appendReasoning(state, event),
      NanobotEventKind.reasoningEnd => _closeReasoning(state),
      NanobotEventKind.message => _appendMessage(state, event),
      NanobotEventKind.fileEdit => _appendFileEdit(state, event),
      NanobotEventKind.goalStatus => _applyGoalStatus(state, event),
      NanobotEventKind.goalState => state.copyWith(goalState: event.goalState),
      NanobotEventKind.streamEnd => _finalizeStreaming(state, event),
      NanobotEventKind.turnEnd => _endTurn(state, event),
      _ => state,
    };
  }

  static NanobotThreadState _appendDelta(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    final chunk = event.text ?? '';
    if (chunk.isEmpty) {
      return state;
    }

    final entries = [...state.entries];
    final index = _lastStreamingAssistantIndex(entries, event.turnId);
    if (index >= 0) {
      final entry = entries[index];
      entries[index] = _applyTurnFields(
        entry.copyWith(content: entry.content + chunk, isStreaming: true),
        event,
        fallbackPhase: 'answer',
      );
    } else {
      entries.add(
        _applyTurnFields(
          NanobotThreadEntry(
            id: _entryId(state, 'assistant'),
            role: NanobotThreadRole.assistant,
            content: chunk,
            createdAt: DateTime.now(),
            isStreaming: true,
          ),
          event,
          fallbackPhase: 'answer',
        ),
      );
    }
    return state.copyWith(entries: entries, isStreaming: true);
  }

  static NanobotThreadState _appendReasoning(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    final chunk = event.text ?? '';
    if (chunk.isEmpty) {
      return state;
    }

    final entries = [...state.entries];
    final index = _lastReasoningTargetIndex(entries, event.turnId);
    if (index >= 0) {
      final entry = entries[index];
      entries[index] = _applyTurnFields(
        entry.copyWith(
          reasoning: (entry.reasoning ?? '') + chunk,
          reasoningStreaming: true,
          isStreaming: true,
        ),
        event,
        fallbackPhase: 'reasoning',
      );
    } else {
      entries.add(
        _applyTurnFields(
          NanobotThreadEntry(
            id: _entryId(state, 'assistant'),
            role: NanobotThreadRole.assistant,
            content: '',
            createdAt: DateTime.now(),
            isStreaming: true,
            reasoning: chunk,
            reasoningStreaming: true,
          ),
          event,
          fallbackPhase: 'reasoning',
        ),
      );
    }
    return state.copyWith(entries: entries, isStreaming: true);
  }

  static NanobotThreadState _closeReasoning(NanobotThreadState state) {
    final entries = [...state.entries];
    for (var i = entries.length - 1; i >= 0; i -= 1) {
      final entry = entries[i];
      if (!entry.reasoningStreaming) {
        continue;
      }
      entries[i] = entry.copyWith(reasoningStreaming: false);
      return state.copyWith(entries: entries);
    }
    return state;
  }

  static NanobotThreadState _appendMessage(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    if (_isTraceMessage(event.kindLabel)) {
      return _appendTrace(state, event);
    }
    if (event.kindLabel == 'reasoning') {
      return _closeReasoning(_appendReasoning(state, event));
    }

    final text = event.text ?? '';
    final media = _mediaFromEvent(event);
    if (text.isEmpty && media.isEmpty) {
      return state;
    }

    final entries = [...state.entries];
    entries.add(
      _applyTurnFields(
        NanobotThreadEntry(
          id: _entryId(state, 'assistant'),
          role: NanobotThreadRole.assistant,
          content: text,
          createdAt: DateTime.now(),
          isStreaming: false,
          latencyMs: event.latencyMs,
          source: event.source,
          agentUi: event.agentUi,
          media: media,
        ),
        event,
        fallbackPhase: 'answer',
      ),
    );
    return state.copyWith(entries: entries);
  }

  static NanobotThreadState _appendTrace(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    final line = _traceLine(event);
    if (line == null) {
      return state;
    }

    final entries = [...state.entries];
    final last = entries.isEmpty ? null : entries.last;
    final toolEvents = [...event.toolEvents];
    if (last != null && last.kind == NanobotThreadEntryKind.trace) {
      entries[entries.length - 1] = _applyTurnFields(
        last.copyWith(
          content: line,
          traces: [...last.traces, line],
          toolEvents: [...last.toolEvents, ...toolEvents],
        ),
        event,
        fallbackPhase: 'activity',
      );
    } else {
      entries.add(
        _applyTurnFields(
          NanobotThreadEntry(
            id: _entryId(state, 'trace'),
            role: NanobotThreadRole.tool,
            kind: NanobotThreadEntryKind.trace,
            content: line,
            traces: [line],
            toolEvents: toolEvents,
            createdAt: DateTime.now(),
          ),
          event,
          fallbackPhase: 'activity',
        ),
      );
    }
    return state.copyWith(entries: entries);
  }

  static NanobotThreadState _appendFileEdit(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    if (event.fileEdits.isEmpty) {
      return state;
    }
    final entries = [
      ...state.entries,
      _applyTurnFields(
        NanobotThreadEntry(
          id: _entryId(state, 'file-edit'),
          role: NanobotThreadRole.tool,
          kind: NanobotThreadEntryKind.fileEdit,
          content: 'Editing files',
          fileEdits: [...event.fileEdits],
          createdAt: DateTime.now(),
        ),
        event,
        fallbackPhase: 'activity',
      ),
    ];
    return state.copyWith(entries: entries, isStreaming: true);
  }

  static NanobotThreadState _applyGoalStatus(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    if (event.status == 'running') {
      return state.copyWith(runStartedAt: event.startedAt, isStreaming: true);
    }
    return state.copyWith(clearRunStartedAt: true);
  }

  static NanobotThreadState _finalizeStreaming(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    final entries = _finalizeEntries(state.entries, event.turnId);
    return state.copyWith(entries: entries, isStreaming: false);
  }

  static NanobotThreadState _endTurn(
    NanobotThreadState state,
    NanobotEvent event,
  ) {
    var entries = _finalizeEntries(state.entries, event.turnId);
    final latencyMs = event.latencyMs;
    if (latencyMs != null && latencyMs >= 0) {
      entries = _stampLastAssistantLatency(entries, latencyMs, event.turnId);
    }
    return state.copyWith(
      entries: entries,
      isStreaming: false,
      clearRunStartedAt: true,
      goalState: event.goalState,
    );
  }

  static List<NanobotThreadEntry> _finalizeEntries(
    List<NanobotThreadEntry> entries,
    String? turnId,
  ) {
    return [
      for (final entry in entries)
        if (entry.isStreaming && _matchesTurn(entry, turnId))
          entry.copyWith(isStreaming: false, reasoningStreaming: false)
        else
          entry,
    ];
  }

  static List<NanobotThreadEntry> _stampLastAssistantLatency(
    List<NanobotThreadEntry> entries,
    int latencyMs,
    String? turnId,
  ) {
    final next = [...entries];
    for (var i = next.length - 1; i >= 0; i -= 1) {
      final entry = next[i];
      if (entry.role == NanobotThreadRole.assistant &&
          entry.kind == NanobotThreadEntryKind.message &&
          _matchesTurn(entry, turnId)) {
        next[i] = entry.copyWith(latencyMs: latencyMs, isStreaming: false);
        break;
      }
    }
    return next;
  }

  static int _lastStreamingAssistantIndex(
    List<NanobotThreadEntry> entries,
    String? turnId,
  ) {
    for (var i = entries.length - 1; i >= 0; i -= 1) {
      final entry = entries[i];
      if (entry.role == NanobotThreadRole.assistant &&
          entry.kind == NanobotThreadEntryKind.message &&
          entry.isStreaming &&
          _matchesTurn(entry, turnId)) {
        return i;
      }
      if (entry.role == NanobotThreadRole.user) {
        break;
      }
    }
    return -1;
  }

  static int _lastReasoningTargetIndex(
    List<NanobotThreadEntry> entries,
    String? turnId,
  ) {
    for (var i = entries.length - 1; i >= 0; i -= 1) {
      final entry = entries[i];
      if (entry.role == NanobotThreadRole.user ||
          entry.kind == NanobotThreadEntryKind.trace) {
        break;
      }
      if (entry.role == NanobotThreadRole.assistant &&
          entry.kind == NanobotThreadEntryKind.message &&
          _matchesTurn(entry, turnId) &&
          (entry.isStreaming ||
              entry.reasoningStreaming ||
              entry.reasoning != null) &&
          entry.content.isEmpty) {
        return i;
      }
    }
    return -1;
  }

  static NanobotThreadEntry _applyTurnFields(
    NanobotThreadEntry entry,
    NanobotEvent event, {
    required String fallbackPhase,
  }) {
    return entry.copyWith(
      turnId: event.turnId,
      turnPhase: event.turnPhase ?? fallbackPhase,
      turnSeq: event.turnSeq,
      source: event.source,
      agentUi: event.agentUi,
    );
  }

  static bool _matchesTurn(NanobotThreadEntry entry, String? turnId) {
    return turnId == null || entry.turnId == null || entry.turnId == turnId;
  }

  static bool _isTraceMessage(String? kind) {
    return kind == 'tool_hint' || kind == 'progress';
  }

  static String? _traceLine(NanobotEvent event) {
    final text = event.text?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
    for (final toolEvent in event.toolEvents) {
      final name = toolEvent['name'];
      if (name is String && name.trim().isNotEmpty) {
        return name;
      }
    }
    return null;
  }

  static List<NanobotMediaAttachment> _mediaFromEvent(NanobotEvent event) {
    return [
      for (final url in event.media) NanobotMediaAttachment.fromUrl(url),
      for (final item in event.mediaUrls) NanobotMediaAttachment.fromJson(item),
    ];
  }

  static String _entryId(NanobotThreadState state, String prefix) {
    return '${state.sessionKey}:$prefix:${state.entries.length + 1}';
  }
}
