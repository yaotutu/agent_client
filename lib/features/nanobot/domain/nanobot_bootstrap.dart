class NanobotBootstrap {
  const NanobotBootstrap({
    required this.token,
    required this.wsPath,
    required this.expiresAt,
    this.wsUrl,
    this.modelName,
    this.runtimeSurface,
  });

  final String token;
  final String wsPath;
  final String? wsUrl;
  final DateTime expiresAt;
  final String? modelName;
  final String? runtimeSurface;

  bool get shouldRefresh {
    return DateTime.now().isAfter(
      expiresAt.subtract(const Duration(seconds: 30)),
    );
  }

  factory NanobotBootstrap.fromJson(Map<String, Object?> json) {
    final token = json['token'];
    final wsPath = json['ws_path'];
    final expiresIn = json['expires_in'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('bootstrap response missing token');
    }
    if (wsPath is! String || wsPath.trim().isEmpty) {
      throw const FormatException('bootstrap response missing ws_path');
    }
    final seconds = expiresIn is num ? expiresIn.toInt() : 300;
    return NanobotBootstrap(
      token: token,
      wsPath: wsPath,
      wsUrl: json['ws_url'] is String ? json['ws_url'] as String : null,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
      modelName: json['model_name'] is String
          ? json['model_name'] as String
          : null,
      runtimeSurface: json['runtime_surface'] is String
          ? json['runtime_surface'] as String
          : null,
    );
  }
}
