class UnknownMarkerData {
  final String id;
  final String oltId;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  UnknownMarkerData({
    required this.id,
    required this.oltId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'oltId': oltId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };

  factory UnknownMarkerData.fromJson(Map<String, dynamic> json) => UnknownMarkerData(
        id: json['id'],
        oltId: json['oltId'],
        name: json['name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        description: json['description'],
      );
}
