import 'dart:convert';

import 'package:agent_client/features/nanobot/data/protocol/nanobot_http_dto.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_bootstrap.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_config.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_message.dart';
import 'package:agent_client/features/nanobot/domain/nanobot_session.dart';
import 'package:dio/dio.dart';

class NanobotApiClient {
  NanobotApiClient({required NanobotConfig config, Dio? dio})
    : _config = config,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final NanobotConfig _config;
  final Dio _dio;
  NanobotBootstrap? _bootstrap;

  NanobotConfig get config => _config;

  Future<NanobotBootstrap> bootstrap({bool forceRefresh = false}) async {
    final cached = _bootstrap;
    if (!forceRefresh && cached != null && !cached.shouldRefresh) {
      return cached;
    }

    final response = await _dio.get<Object?>(
      '/webui/bootstrap',
      options: Options(
        headers: _config.secret.trim().isEmpty
            ? null
            : {'X-Nanobot-Auth': _config.secret.trim()},
      ),
    );
    final data = _asMap(response.data);
    final next = NanobotBootstrap.fromJson(data);
    _bootstrap = next;
    return next;
  }

  Future<List<NanobotSessionSummary>> listSessions() async {
    final response = await _dio.get<Object?>(
      '/api/sessions',
      options: await _authOptions(),
    );
    final data = _asMap(response.data);
    final rows = data['sessions'];
    if (rows is! List) {
      return const [];
    }
    return [
      for (final row in rows)
        if (row is Map)
          NanobotSessionSummary.fromJson(Map<String, Object?>.from(row)),
    ];
  }

  Future<List<NanobotMessage>> fetchWebuiThread({
    required String sessionKey,
    required String chatId,
    int limit = 120,
    String? before,
  }) async {
    final dto = await fetchWebuiThreadPage(
      sessionKey: sessionKey,
      limit: limit,
      before: before,
    );
    return [
      for (final row in dto.messages)
        NanobotMessage.fromWebuiJson(
          json: row,
          sessionKey: sessionKey,
          chatId: chatId,
        ),
    ];
  }

  Future<NanobotWebuiThreadDto> fetchWebuiThreadPage({
    required String sessionKey,
    int limit = 120,
    String? before,
  }) async {
    final query = <String, Object?>{'limit': limit, 'direction': 'latest'};
    final trimmedBefore = before?.trim();
    if (trimmedBefore != null && trimmedBefore.isNotEmpty) {
      query['before'] = trimmedBefore;
    }
    try {
      final response = await _dio.get<Object?>(
        '/api/sessions/${Uri.encodeComponent(sessionKey)}/webui-thread',
        queryParameters: query,
        options: await _authOptions(),
      );
      return NanobotWebuiThreadDto.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return NanobotWebuiThreadDto(
          schemaVersion: 0,
          sessionKey: sessionKey,
          page: const NanobotWebuiThreadPageDto(loadedMessageCount: 0),
        );
      }
      rethrow;
    }
  }

  Future<NanobotFilePreviewDto> fetchFilePreview({
    required String sessionKey,
    required String path,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/sessions/${Uri.encodeComponent(sessionKey)}/file-preview',
      queryParameters: {'path': path},
      options: await _authOptions(),
    );
    return NanobotFilePreviewDto.fromJson(_asMap(response.data));
  }

  Future<NanobotWorkspacesDto> fetchWorkspaces() async {
    final response = await _dio.get<Object?>(
      '/api/workspaces',
      options: await _authOptions(),
    );
    return NanobotWorkspacesDto.fromJson(_asMap(response.data));
  }

  Future<List<NanobotSlashCommandDto>> listSlashCommands() async {
    final response = await _dio.get<Object?>(
      '/api/commands',
      options: await _authOptions(),
    );
    return NanobotSlashCommandDto.listFromJson(_asMap(response.data));
  }

  Future<NanobotSidebarStateDto> fetchSidebarState() async {
    final response = await _dio.get<Object?>(
      '/api/webui/sidebar-state',
      options: await _authOptions(),
    );
    return NanobotSidebarStateDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSidebarStateDto> updateSidebarState(
    NanobotSidebarStateDto state,
  ) async {
    final response = await _dio.get<Object?>(
      '/api/webui/sidebar-state/update',
      queryParameters: {'state': jsonEncode(state.toJson())},
      options: await _authOptions(),
    );
    return NanobotSidebarStateDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> fetchSettings() async {
    final response = await _dio.get<Object?>(
      '/api/settings',
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsUsageDto> fetchSettingsUsage() async {
    final response = await _dio.get<Object?>(
      '/api/settings/usage',
      options: await _authOptions(),
    );
    return NanobotSettingsUsageDto.fromJson(_asMap(response.data));
  }

  Future<NanobotVersionCheckDto> checkVersion() async {
    final response = await _dio.get<Object?>(
      '/api/settings/version-check',
      options: await _authOptions(),
    );
    return NanobotVersionCheckDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateWebSearchSettings({
    required String provider,
    required int maxResults,
    required int timeoutSeconds,
    required bool useJinaReader,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/web-search/update',
      queryParameters: {
        'provider': provider,
        'max_results': maxResults,
        'timeout': timeoutSeconds,
        'use_jina_reader': useJinaReader,
      },
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateImageGenerationSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String defaultAspectRatio,
    required String defaultImageSize,
    required int maxImagesPerTurn,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/image-generation/update',
      queryParameters: {
        'enabled': enabled,
        'provider': provider,
        'model': model,
        'default_aspect_ratio': defaultAspectRatio,
        'default_image_size': defaultImageSize,
        'max_images_per_turn': maxImagesPerTurn,
      },
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateTranscriptionSettings({
    required bool enabled,
    required String provider,
    required String model,
    required String language,
    required int maxDurationSec,
    required int maxUploadMb,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/transcription/update',
      queryParameters: {
        'enabled': enabled,
        'provider': provider,
        'model': model,
        'language': language,
        'max_duration_sec': maxDurationSec,
        'max_upload_mb': maxUploadMb,
      },
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateNetworkSafetySettings({
    required bool webuiAllowLocalServiceAccess,
    required String webuiDefaultAccessMode,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/network-safety/update',
      queryParameters: {
        'webui_allow_local_service_access': webuiAllowLocalServiceAccess,
        'webui_default_access_mode': webuiDefaultAccessMode,
      },
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateRuntimeSettings({
    required String timezone,
    required String botName,
    required String botIcon,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/update',
      queryParameters: {
        'timezone': timezone,
        'bot_name': botName,
        'bot_icon': botIcon,
      },
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateModelSettings({
    required String modelPreset,
    String? model,
    String? provider,
    int? contextWindowTokens,
  }) async {
    final queryParameters = <String, Object?>{'model_preset': modelPreset};
    if (model != null) {
      queryParameters['model'] = model;
    }
    if (provider != null) {
      queryParameters['provider'] = provider;
    }
    if (contextWindowTokens != null) {
      queryParameters['context_window_tokens'] = contextWindowTokens;
    }
    final response = await _dio.get<Object?>(
      '/api/settings/update',
      queryParameters: queryParameters,
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> createModelConfiguration({
    required String label,
    required String provider,
    required String model,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/model-configurations/create',
      queryParameters: {'label': label, 'provider': provider, 'model': model},
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateModelConfiguration({
    required String name,
    required String label,
    required String provider,
    required String model,
    int? contextWindowTokens,
  }) async {
    final queryParameters = <String, Object?>{
      'name': name,
      'label': label,
      'provider': provider,
      'model': model,
    };
    if (contextWindowTokens != null) {
      queryParameters['context_window_tokens'] = contextWindowTokens;
    }
    final response = await _dio.get<Object?>(
      '/api/settings/model-configurations/update',
      queryParameters: queryParameters,
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> loginProviderOAuth(String provider) async {
    final response = await _dio.get<Object?>(
      '/api/settings/provider/oauth-login',
      queryParameters: {'provider': provider},
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> logoutProviderOAuth(String provider) async {
    final response = await _dio.get<Object?>(
      '/api/settings/provider/oauth-logout',
      queryParameters: {'provider': provider},
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSettingsDto> updateProviderSettings({
    required String provider,
    String? apiKey,
    String? apiBase,
    String? apiType,
  }) async {
    final queryParameters = <String, Object?>{'provider': provider};
    if (apiKey != null) {
      queryParameters['api_key'] = apiKey;
    }
    if (apiBase != null) {
      queryParameters['api_base'] = apiBase;
    }
    if (apiType != null) {
      queryParameters['api_type'] = apiType;
    }
    final response = await _dio.get<Object?>(
      '/api/settings/provider/update',
      queryParameters: queryParameters,
      options: await _authOptions(),
    );
    return NanobotSettingsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSkillsDto> fetchSkills() async {
    final response = await _dio.get<Object?>(
      '/api/webui/skills',
      options: await _authOptions(),
    );
    return NanobotSkillsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSkillDetailDto> fetchSkillDetail(String name) async {
    final response = await _dio.get<Object?>(
      '/api/webui/skills/${Uri.encodeComponent(name)}',
      options: await _authOptions(),
    );
    return NanobotSkillDetailDto.fromJson(_asMap(response.data));
  }

  Future<NanobotCliAppsDto> fetchCliApps() async {
    final response = await _dio.get<Object?>(
      '/api/settings/cli-apps',
      options: await _authOptions(),
    );
    return NanobotCliAppsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotCliAppsDto> fetchInstalledCliApps() async {
    final response = await _dio.get<Object?>(
      '/api/settings/cli-apps',
      queryParameters: {'installed_only': 1},
      options: await _authOptions(),
    );
    return NanobotCliAppsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotFeaturesDto> fetchNanobotFeatures() async {
    final response = await _dio.get<Object?>(
      '/api/settings/nanobot-features',
      options: await _authOptions(),
    );
    return NanobotFeaturesDto.fromJson(_asMap(response.data));
  }

  Future<NanobotMcpPresetsDto> fetchMcpPresets() async {
    final response = await _dio.get<Object?>(
      '/api/settings/mcp-presets',
      options: await _authOptions(),
    );
    return NanobotMcpPresetsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotCliAppsDto> runCliAppAction({
    required String action,
    required String name,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/cli-apps/$action',
      queryParameters: {'name': name},
      options: await _authOptions(),
    );
    return NanobotCliAppsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotFeaturesDto> runNanobotFeatureAction({
    required String action,
    required String name,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/nanobot-features/$action',
      queryParameters: {'name': name},
      options: await _authOptions(),
    );
    return NanobotFeaturesDto.fromJson(_asMap(response.data));
  }

  Future<NanobotMcpPresetsDto> runMcpPresetAction({
    required String action,
    required String name,
    Map<String, Object?> values = const {},
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/mcp-presets/$action',
      queryParameters: {'name': name},
      options: await _mcpOptions(values),
    );
    return NanobotMcpPresetsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotMcpPresetsDto> saveCustomMcpServer(
    Map<String, Object?> values,
  ) async {
    final response = await _dio.get<Object?>(
      '/api/settings/mcp-presets/custom',
      options: await _mcpOptions(values),
    );
    return NanobotMcpPresetsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotMcpPresetsDto> importMcpConfig(String config) async {
    final response = await _dio.get<Object?>(
      '/api/settings/mcp-presets/import',
      options: await _mcpOptions({'config': config}),
    );
    return NanobotMcpPresetsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotMcpPresetsDto> updateMcpServerTools({
    required String name,
    required List<String> enabledTools,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/settings/mcp-presets/tools',
      options: await _mcpOptions({'name': name, 'enabled_tools': enabledTools}),
    );
    return NanobotMcpPresetsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotProviderModelsDto> fetchProviderModels(String provider) async {
    final response = await _dio.get<Object?>(
      '/api/settings/provider-models',
      queryParameters: {'provider': provider},
      options: await _authOptions(),
    );
    return NanobotProviderModelsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotAutomationsDto> fetchAutomations() async {
    final response = await _dio.get<Object?>(
      '/api/webui/automations',
      options: await _authOptions(),
    );
    return NanobotAutomationsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotAutomationsDto> runAutomationAction({
    required String action,
    required String id,
  }) async {
    final response = await _dio.get<Object?>(
      '/api/webui/automations/$action',
      queryParameters: {'id': id},
      options: await _authOptions(),
    );
    return NanobotAutomationsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotAutomationsDto> updateAutomation({
    required String id,
    required Map<String, Object?> values,
  }) async {
    final authOptions = await _authOptions();
    final automationValues = _encodedAutomationValues(values);
    final headers = {...?authOptions.headers};
    if (automationValues != null) {
      headers['X-Nanobot-Automation-Values'] = automationValues;
    }
    final response = await _dio.get<Object?>(
      '/api/webui/automations/update',
      queryParameters: {'id': id},
      options: authOptions.copyWith(headers: headers),
    );
    return NanobotAutomationsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotAutomationsDto> fetchSessionAutomations(
    String sessionKey,
  ) async {
    final response = await _dio.get<Object?>(
      '/api/sessions/${Uri.encodeComponent(sessionKey)}/automations',
      options: await _authOptions(),
    );
    return NanobotAutomationsDto.fromJson(_asMap(response.data));
  }

  Future<NanobotSessionDeleteResultDto> deleteSession({
    required String sessionKey,
    bool deleteAutomations = false,
  }) async {
    final query = <String, Object?>{};
    if (deleteAutomations) {
      query['delete_automations'] = true;
    }
    final response = await _dio.get<Object?>(
      '/api/sessions/${Uri.encodeComponent(sessionKey)}/delete',
      queryParameters: query,
      options: await _authOptions(),
    );
    return NanobotSessionDeleteResultDto.fromJson(_asMap(response.data));
  }

  Future<Options> _authOptions() async {
    final token = (await bootstrap()).token;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Options> _mcpOptions(Map<String, Object?> values) async {
    final authOptions = await _authOptions();
    final mcpValues = _encodedMcpValues(values);
    if (mcpValues == null) {
      return authOptions;
    }
    return authOptions.copyWith(
      headers: {...?authOptions.headers, 'X-Nanobot-MCP-Values': mcpValues},
    );
  }

  Map<String, Object?> _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      return Map<String, Object?>.from(value);
    }
    throw const FormatException('nanobot API returned non-object JSON');
  }

  String? _encodedAutomationValues(Map<String, Object?> values) {
    final payload = <String, Object?>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          payload[entry.key] = trimmed;
        }
        continue;
      }
      payload[entry.key] = value;
    }
    if (payload.isEmpty) {
      return null;
    }
    return Uri.encodeComponent(jsonEncode(payload));
  }

  String? _encodedMcpValues(Map<String, Object?> values) {
    final payload = <String, Object?>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          payload[entry.key] = trimmed;
        }
        continue;
      }
      payload[entry.key] = value;
    }
    if (payload.isEmpty) {
      return null;
    }
    return jsonEncode(payload);
  }
}
