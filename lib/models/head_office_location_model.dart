class HeadOfficeLocation {
  final String? id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  HeadOfficeLocation({
    this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  HeadOfficeLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return HeadOfficeLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory HeadOfficeLocation.fromJson(Map<String, dynamic> json) {
    return HeadOfficeLocation(
      id: json['_id'] as String?,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
