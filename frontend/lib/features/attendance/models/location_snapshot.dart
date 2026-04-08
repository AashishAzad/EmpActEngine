class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String address;
}