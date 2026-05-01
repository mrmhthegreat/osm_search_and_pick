/// Represents a Latitude and Longitude coordinate pair.
class LatLong {
  final double latitude;
  final double longitude;
  const LatLong(this.latitude, this.longitude);

  @override
  String toString() => 'LatLong($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      other is LatLong &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
