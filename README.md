# Agent Client

Flutter client for agent backends. The first backend adapter targets Agent
Control v1, but UI and application state depend on feature ports so more agent
types can be added behind the same contracts.

## Architecture

- Feature `application/` and `presentation/` layers depend on domain models and
  repository ports, not Agent Control DTOs.
- `lib/features/agent_control` is one backend adapter. It owns Dio calls, SSE
  parsing, API exceptions, and raw protocol DTO parsing.
- `lib/features/agents/data/agent_registry_repository.dart` exposes the generic
  agent registry port. `AgentControlAgentRegistryRepository` is the current
  implementation.
- `lib/features/chat/data/agent_chat_repository.dart` is the generic chat port.
  `agent_chat_repository_provider.dart` wires the current Agent Control adapter.
- `lib/features/chat/data/agent_control_chat_services.dart` splits Agent Control
  chat behavior into readiness, session, history, and streaming-turn services.
- Files, settings, commands, and git each expose generic domain types; their
  current data repositories map Agent Control DTOs into those types.
- `lib/features/chat/application` owns Riverpod state for active chat messages
  and session lists.
- `lib/features/chat/data/chat_cache_provider.dart` uses Drift as the default
  durable cache. `InMemoryChatCacheStore` is only for tests and provider
  overrides.
- Cache reads and clears are scoped by both `agentId` and `sessionId`; creating a
  new session does not delete messages from other sessions.

To add another agent backend, implement the same ports and swap/wrap the
providers:

- `AgentRegistryRepository`
- `AgentChatRepository`
- `AgentResourcesRepository`
- `AgentSettingsRepository`
- `AgentGitRepository`

`Agent` includes `backendId` and `backendAgentId` fields so future routing can
distinguish backend identity from display identity without changing UI models.

## Configuration

By default, the app connects to the bundled Agent Control endpoint configured in
`lib/core/config/app_config.dart` and uses the bundled API key.

```sh
flutter run
```

The same server URL and API key can be changed from the in-app Settings page.
Override them at launch only when you need a temporary build/run value:

```sh
flutter run \
  --dart-define=AGENT_API_BASE_URL=http://127.0.0.1:9800 \
  --dart-define=AGENT_API_KEY=your-api-key
```

Authenticated Agent Control endpoints require an API key; `/health` is the only
unauthenticated endpoint.

## Development

```sh
flutter analyze
flutter test --no-pub
```

Use plain `flutter test` after Flutter can refresh generated platform package
files in `ios/Flutter/ephemeral`.

When tests need fakes, override providers in `ProviderScope`, especially:

- `agentControlApiClientProvider`
- `agentChatRepositoryProvider`
- `chatCacheStoreProvider`
- `agentFilesProvider`
- `agentCommandsProvider`
