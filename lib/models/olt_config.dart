class OltConfig {
  final String id;
  final String name;
  final String url;
  final String username;
  final String password;
  final String model;
  final String? submodel;
  final int refreshTimeMinutes;
  final int? lastRefreshTime;
  final String? onuIcon;
  final String? odpIcon;
  final double? markerSize;
  final double? lastMapLatitude;
  final double? lastMapLongitude;
  final double? lastMapZoom;

  OltConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    required this.model,
    this.submodel,
    this.refreshTimeMinutes = 1,
    this.lastRefreshTime,
    this.onuIcon,
    this.odpIcon,
    this.markerSize,
    this.lastMapLatitude,
    this.lastMapLongitude,
    this.lastMapZoom,
  });

  factory OltConfig.fromJson(Map<String, dynamic> json) {
    return OltConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      model: json['model'] ?? '',
      submodel: json['submodel'],
      refreshTimeMinutes: json['refreshTimeMinutes'] ?? 1,
      lastRefreshTime: json['lastRefreshTime'],
      onuIcon: json['onuIcon'],
      odpIcon: json['odpIcon'],
      markerSize: json['markerSize']?.toDouble(),
      lastMapLatitude: json['lastMapLatitude']?.toDouble(),
      lastMapLongitude: json['lastMapLongitude']?.toDouble(),
      lastMapZoom: json['lastMapZoom']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'username': username,
      'password': password,
      'model': model,
      'submodel': submodel,
      'refreshTimeMinutes': refreshTimeMinutes,
      'lastRefreshTime': lastRefreshTime,
      'onuIcon': onuIcon,
      'odpIcon': odpIcon,
      'markerSize': markerSize,
      'lastMapLatitude': lastMapLatitude,
      'lastMapLongitude': lastMapLongitude,
      'lastMapZoom': lastMapZoom,
    };
  }
}
