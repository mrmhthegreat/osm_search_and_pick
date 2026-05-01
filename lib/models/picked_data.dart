import 'package:osm_search_and_pick/models/lat_long.dart';

/// Data returned when a location is picked.
class PickedData {
  /// The GPS coordinates of the picked location.
  final LatLong latLong;

  /// The full display name of the address.
  final String addressName;

  /// A map containing detailed address components (city, country, etc.).
  final Map<String, dynamic> address;

  const PickedData(this.latLong, this.addressName, this.address);

  @override
  String toString() => 'PickedData($addressName, $latLong)';
}
