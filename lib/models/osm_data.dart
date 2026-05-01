/// Represents a search result from the Nominatim API.
class OSMdata {
  final String displayname;
  final double lat;
  final double lon;

  const OSMdata({
    required this.displayname,
    required this.lat,
    required this.lon,
  });

  @override
  String toString() => '$displayname ($lat, $lon)';

  @override
  bool operator ==(Object other) =>
      other is OSMdata && other.displayname == displayname;

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}
