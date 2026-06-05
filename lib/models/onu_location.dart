class OnuLocationData {
  final String oltId;
  final String onuId;
  final double latitude;
  final double longitude;
  final String? cableName;
  final String? cableLength;
  final String? coreColor;
  final String? tubeColor;
  final String? odpId;
  final String? icon;
  final List<Map<String, double>>? cablePath;

  OnuLocationData({
    required this.oltId,
    required this.onuId,
    required this.latitude,
    required this.longitude,
    this.cableName,
    this.cableLength,
    this.coreColor,
    this.tubeColor,
    this.odpId,
    this.icon,
    this.cablePath,
  });

  factory OnuLocationData.fromJson(Map<String, dynamic> json) {
    return OnuLocationData(
      oltId: json['oltId'] ?? '',
      onuId: json['onuId'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      cableName: json['cableName'],
      cableLength: json['cableLength'],
      coreColor: json['coreColor'],
      tubeColor: json['tubeColor'],
      odpId: json['odpId'],
      icon: json['icon'],
      cablePath: (json['cablePath'] as List<dynamic>?)
          ?.map((e) => Map<String, double>.from(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oltId': oltId,
      'onuId': onuId,
      'latitude': latitude,
      'longitude': longitude,
      'cableName': cableName,
      'cableLength': cableLength,
      'coreColor': coreColor,
      'tubeColor': tubeColor,
      'odpId': odpId,
      'icon': icon,
      'cablePath': cablePath,
    };
  }
}
