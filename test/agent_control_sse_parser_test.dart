import 'package:agent_client/features/agent_control/data/agent_control_sse_parser.dart';
import 'package:agent_client/features/agent_control/domain/agent_control_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Agent Control stream events and done marker', () {
    final parser = AgentControlSseParser();

    final events = parser.parseChunk('''
data: {"type":"goal_status","state":"running","startedAt":1780023022.32}

data: {"type":"reasoning","text":"Thinking"}

data: {"type":"reasoning_done"}

data: {"type":"text","text":"Hel"}

data: {"type":"progress","text":"Running command"}

data: {"type":"tool_hint","text":"Searching","toolEvents":[{"name":"rg"}]}

data: {"type":"goal_state","goalState":{"active":true}}

data: {"type":"text","text":"lo"}

data: {"type":"done","latencyMs":2653,"goalState":{"active":false}}

data: [DONE]

''');

    expect(events.map((event) => event.type), [
      AgentControlStreamEventType.goalStatus,
      AgentControlStreamEventType.reasoning,
      AgentControlStreamEventType.reasoningDone,
      AgentControlStreamEventType.text,
      AgentControlStreamEventType.progress,
      AgentControlStreamEventType.toolHint,
      AgentControlStreamEventType.goalState,
      AgentControlStreamEventType.text,
      AgentControlStreamEventType.done,
      AgentControlStreamEventType.doneMarker,
    ]);
    expect(events[0].state, 'running');
    expect(events[1].text, 'Thinking');
    expect(events[3].text, 'Hel');
    expect(events[5].toolEvents, [
      {'name': 'rg'},
    ]);
    expect(events[6].goalState, {'active': true});
    expect(events[8].latencyMs, 2653);
  });

  test('buffers chunks split across network packets', () {
    final parser = AgentControlSseParser();

    expect(parser.parseChunk('data: {"type":"text","text":"Hel'), isEmpty);

    final events = parser.parseChunk('''
lo"}

data: {"type":"error","message":"boom"}

data: [DONE]

''');

    expect(events, hasLength(3));
    expect(events[0].type, AgentControlStreamEventType.text);
    expect(events[0].text, 'Hello');
    expect(events[1].type, AgentControlStreamEventType.error);
    expect(events[1].message, 'boom');
    expect(events[2].type, AgentControlStreamEventType.doneMarker);
  });
}
