import 'dart:convert';
import 'dart:io';

import 'package:agent_client/core/config/app_config_model.dart';
import 'package:agent_client/core/config/app_config_store_contract.dart';
import 'package:path_provider/path_provider.dart';

AppConfigStore createAppConfigStore() {
  return FileAppConfigStore();
}

typedef AppConfigDirectoryProvider = Future<Directory> Function();

class FileAppConfigStore implements AppConfigStore {
  FileAppConfigStore({AppConfigDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final AppConfigDirectoryProvider _directoryProvider;

  @override
  Future<AppConfig?> load() async {
    try {
      final file = await _configFile();
      if (!await file.exists()) {
        return null;
      }

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) {
        return AppConfig.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppConfig.fromJson(Map<String, Object?>.from(decoded));
      }
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<void> save(AppConfig config) async {
    final file = await _configFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(config.toJson()));
  }

  Future<File> _configFile() async {
    final directory = await _directoryProvider();
    return File('${directory.path}/agent_client_config.json');
  }
}
