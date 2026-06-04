class OdpData {
  final String id;
  final String oltId;
  final String name;
  final double latitude;
  final double longitude;
  final String? parentId;
  final int portCount;
  final double? cachedAvgRxPower;
  final String? cableName;
  final String? coreColor;
  final String? tubeColor;
  final List<String> onuIds;

  OdpData({
    required this.id,
    required this.oltId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.parentId,
    required this.portCount,
    this.cachedAvgRxPower,
    this.cableName,
    this.coreColor,
    this.tubeColor,
    required this.onuIds,
  });

  factory OdpData.fromJson(Map<String, dynamic> json) {
    return OdpData(
      id: json['id'] ?? '',
      oltId: json['oltId'] ?? '',
      name: json['name'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      parentId: json['parentId'],
      portCount: json['portCount'] ?? 8,
      cachedAvgRxPower: json['cachedAvgRxPower']?.toDouble(),
      cableName: json['cableName'],
      coreColor: json['coreColor'],
      tubeColor: json['tubeColor'],
      onuIds: List<String>.from(json['onuIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oltId': oltId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'parentId': parentId,
      'portCount': portCount,
      'cachedAvgRxPower': cachedAvgRxPower,
      'cableName': cableName,
      'coreColor': coreColor,
      'tubeColor': tubeColor,
      'onuIds': onuIds,
    };
  }
}
