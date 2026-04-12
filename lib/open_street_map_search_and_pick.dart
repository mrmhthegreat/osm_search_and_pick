// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:osm_search_and_pick/widgets/wide_button.dart';

/// A Flutter place search and location picker widget that uses Open Street Map.
///
/// It allows users to search for places using Nominatim and select a precise
/// location by moving the map and pinning it.
class OpenStreetMapSearchAndPick extends StatefulWidget {
  /// Callback function called when the user selects a location.
  final void Function(PickedData pickedData) onPicked;

  /// Icon for the zoom-in button.
  final IconData zoomInIcon;

  /// Icon for the zoom-out button.
  final IconData zoomOutIcon;

  /// Icon for the current location button.
  final IconData currentLocationIcon;

  /// Icon for the pin displayed in the center of the map.
  final IconData locationPinIcon;

  /// Color for the zoom and action buttons.
  final Color buttonColor;

  /// Color for the text/icons inside the buttons.
  final Color buttonTextColor;

  /// Color for the center location pin icon.
  final Color locationPinIconColor;

  /// Label text displayed above the center pin.
  final String locationPinText;

  /// Text style for the label above the center pin.
  final TextStyle locationPinTextStyle;

  /// Text displayed on the main "Set Location" button.
  final String buttonText;

  /// Hint text for the search bar.
  final String hintText;

  /// Height of the main "Set Location" button.
  final double buttonHeight;

  /// Width of the main "Set Location" button.
  final double buttonWidth;

  /// Text style for the text on the main "Set Location" button.
  final TextStyle buttonTextStyle;

  /// The base URI for the Nominatim API. Defaults to 'https://nominatim.openstreetmap.org'.
  final String baseUri;

  /// The initial location where the map should be centered.
  /// If null, it will default to the user's current location.
  final LatLong? initialCenter;

  /// Zoom level when the map is initialized. Defaults to 15.0.
  final double initialZoom;

  /// Maximum zoom level of the map. Defaults to 18.0.
  final double maxZoom;

  /// Minimum zoom level of the map. Defaults to 6.0.
  final double minZoom;

  /// The URL template for the TileLayer. Defaults to 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'.
  final String tileUrlTemplate;

  /// Border radius of the main 'Set Location' button. Defaults to 5.0.
  final double buttonBorderRadius;

  /// Elevation of the main 'Set Location' button. Defaults to 2.0.
  final double buttonElevation;

  /// Whether to show the zoom in/out buttons. Defaults to true.
  final bool showZoomButtons;

  /// Whether to show the current location button. Defaults to true.
  final bool showCurrentLocationButton;

  /// Whether to show the search bar. Defaults to true.
  final bool showSearchBar;

  /// Whether to show the main "Set Location" button at the bottom. Defaults to true.
  final bool showSetLocationButton;

  /// The application package name used to identify the app to the OSM tile server.
  /// It is highly recommended to set this to your app's package name to comply with
  /// OSM Tile Usage Policy and avoid getting a 403 Forbidden error.
  final String userAgentPackageName;

  const OpenStreetMapSearchAndPick({
    super.key,
    required this.onPicked,
    this.zoomOutIcon = Icons.zoom_out_map,
    this.zoomInIcon = Icons.zoom_in_map,
    this.currentLocationIcon = Icons.my_location,
    this.buttonColor = Colors.blue,
    this.locationPinIconColor = Colors.blue,
    this.locationPinText = 'Location',
    this.locationPinTextStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
    this.hintText = 'Search Location',
    this.buttonTextStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    this.buttonTextColor = Colors.white,
    this.buttonText = 'Set Current Location',
    this.buttonHeight = 50,
    this.buttonWidth = 200,
    this.baseUri = 'https://nominatim.openstreetmap.org',
    this.locationPinIcon = Icons.location_on,
    this.initialCenter,
    this.userAgentPackageName = 'osm_search_and_pick',
    this.initialZoom = 15.0,
    this.maxZoom = 18.0,
    this.minZoom = 6.0,
    this.tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.buttonBorderRadius = 5.0,
    this.buttonElevation = 2.0,
    this.showZoomButtons = true,
    this.showCurrentLocationButton = true,
    this.showSearchBar = true,
    this.showSetLocationButton = true,
  });

  @override
  State<OpenStreetMapSearchAndPick> createState() =>
      _OpenStreetMapSearchAndPickState();
}

class _OpenStreetMapSearchAndPickState
    extends State<OpenStreetMapSearchAndPick> {
  MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<OSMdata> _options = <OSMdata>[];
  Timer? _debounce;
  var client = http.Client();
  late Future<Position?> latlongFuture;

  Future<Position?> getCurrentPosLatLong() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();

    /// do not have location permission
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      return await getPosition(locationPermission);
    }

    /// have location permission
    Position position = await Geolocator.getCurrentPosition();
    setNameCurrentPosAtInit(position.latitude, position.longitude);
    return position;
  }

  Future<Position?> getPosition(LocationPermission locationPermission) async {
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      return null;
    }
    Position position = await Geolocator.getCurrentPosition();
    setNameCurrentPosAtInit(position.latitude, position.longitude);
    return position;
  }

  void setNameCurrentPos() async {
    double latitude = _mapController.camera.center.latitude;
    double longitude = _mapController.camera.center.longitude;
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }
    String url =
        '${widget.baseUri}/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

    var response = await client.get(Uri.parse(url), headers: {
      'User-Agent': widget.userAgentPackageName,
    });
    // var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;

    _searchController.text =
        decodedResponse['display_name'] ?? "MOVE TO CURRENT POSITION";
    setState(() {});
  }

  void setNameCurrentPosAtInit(double latitude, double longitude) async {
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }

    String url =
        '${widget.baseUri}/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

    var response = await client.get(Uri.parse(url), headers: {
      'User-Agent': widget.userAgentPackageName,
    });
    // var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;

    _searchController.text =
        decodedResponse['display_name'] ?? "MOVE TO CURRENT POSITION";
  }

  @override
  void initState() {
    _mapController = MapController();

    _mapController.mapEventStream.listen(
      (event) async {
        if (event is MapEventMoveEnd) {
          var client = http.Client();
          String url =
              '${widget.baseUri}/reverse?format=json&lat=${event.camera.center.latitude}&lon=${event.camera.center.longitude}&zoom=18&addressdetails=1';

          var response = await client.get(Uri.parse(url), headers: {
            'User-Agent': widget.userAgentPackageName,
          });
          // var response = await client.post(Uri.parse(url));
          var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes))
              as Map<dynamic, dynamic>;

          _searchController.text = decodedResponse['display_name'];
          setState(() {});
        }
      },
    );

    latlongFuture = getCurrentPosLatLong();

    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // String? _autocompleteSelection;
    OutlineInputBorder inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: widget.buttonColor),
    );
    OutlineInputBorder inputFocusBorder = OutlineInputBorder(
      borderSide: BorderSide(color: widget.buttonColor, width: 3.0),
    );
    return FutureBuilder<Position?>(
      future: latlongFuture,
      builder: (context, snapshot) {
        LatLng? mapCentre;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong"),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          mapCentre = LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
        } else if (widget.initialCenter != null) {
          mapCentre = LatLng(
              widget.initialCenter!.latitude, widget.initialCenter!.longitude);
        }
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: MapOptions(
                      initialCenter: mapCentre ?? const LatLng(0, 0),
                      initialZoom: widget.initialZoom,
                      maxZoom: widget.maxZoom,
                      minZoom: widget.minZoom),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      urlTemplate: widget.tileUrlTemplate,
                      userAgentPackageName: widget.userAgentPackageName,
                      // attributionBuilder: (_) {
                      //   return Text("© OpenStreetMap contributors");
                      // },
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.locationPinText,
                            style: widget.locationPinTextStyle,
                            textAlign: TextAlign.center),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: Icon(
                            widget.locationPinIcon,
                            size: 50,
                            color: widget.locationPinIconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.showZoomButtons)
                Positioned(
                  bottom: 180,
                  right: 5,
                  child: FloatingActionButton(
                    heroTag: 'btn1',
                    backgroundColor: widget.buttonColor,
                    onPressed: () {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom + 1);
                    },
                    child: Icon(
                      widget.zoomInIcon,
                      color: widget.buttonTextColor,
                    ),
                  ),
                ),
              if (widget.showZoomButtons)
                Positioned(
                  bottom: 120,
                  right: 5,
                  child: FloatingActionButton(
                    heroTag: 'btn2',
                    backgroundColor: widget.buttonColor,
                    onPressed: () {
                      _mapController.move(_mapController.camera.center,
                          _mapController.camera.zoom - 1);
                    },
                    child: Icon(
                      widget.zoomOutIcon,
                      color: widget.buttonTextColor,
                    ),
                  ),
                ),
              if (widget.showCurrentLocationButton)
                Positioned(
                  bottom: 60,
                  right: 5,
                  child: FloatingActionButton(
                    heroTag: 'btn3',
                    backgroundColor: widget.buttonColor,
                    onPressed: () async {
                      if (mapCentre != null) {
                        _mapController.move(
                            LatLng(mapCentre.latitude, mapCentre.longitude),
                            _mapController.camera.zoom);
                      } else {
                        _mapController.move(
                            LatLng(50.5, 30.51), _mapController.camera.zoom);
                      }
                      setNameCurrentPos();
                    },
                    child: Icon(
                      widget.currentLocationIcon,
                      color: widget.buttonTextColor,
                    ),
                  ),
                ),
              if (widget.showSearchBar)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              border: inputBorder,
                              focusedBorder: inputFocusBorder,
                            ),
                            onChanged: (String value) {
                              if (_debounce?.isActive ?? false) {
                                _debounce?.cancel();
                              }

                              _debounce = Timer(
                                  const Duration(milliseconds: 2000), () async {
                                if (kDebugMode) {
                                  print(value);
                                }
                                var client = http.Client();
                                try {
                                  String url =
                                      '${widget.baseUri}/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
                                  if (kDebugMode) {
                                    print(url);
                                  }
                                  var response = await client.get(Uri.parse(url),
                                      headers: {
                                        'User-Agent':
                                            widget.userAgentPackageName,
                                      });
                                  // var response = await client.post(Uri.parse(url));
                                  var decodedResponse = jsonDecode(
                                          utf8.decode(response.bodyBytes))
                                      as List<dynamic>;
                                  if (kDebugMode) {
                                    print(decodedResponse);
                                  }
                                  _options = decodedResponse
                                      .map(
                                        (e) => OSMdata(
                                          displayname: e['display_name'],
                                          lat: double.parse(e['lat']),
                                          lon: double.parse(e['lon']),
                                        ),
                                      )
                                      .toList();
                                  setState(() {});
                                } finally {
                                  client.close();
                                }

                                setState(() {});
                              });
                            }),
                        StatefulBuilder(
                          builder: ((context, setState) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  _options.length > 5 ? 5 : _options.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_options[index].displayname),
                                  subtitle: Text(
                                      '${_options[index].lat},${_options[index].lon}'),
                                  onTap: () {
                                    _mapController.move(
                                        LatLng(_options[index].lat,
                                            _options[index].lon),
                                        15.0);

                                    _focusNode.unfocus();
                                    _options.clear();
                                    setState(() {});
                                  },
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              if (widget.showSetLocationButton)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: WideButton(
                        widget.buttonText,
                        textStyle: widget.buttonTextStyle,
                        height: widget.buttonHeight,
                        width: widget.buttonWidth,
                        onPressed: () async {
                          final value = await pickData();
                          widget.onPicked(value);
                        },
                        backgroundColor: widget.buttonColor,
                        foregroundColor: widget.buttonTextColor,
                        borderRadius: widget.buttonBorderRadius,
                        elevation: widget.buttonElevation,
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Future<PickedData> pickData() async {
    LatLong center = LatLong(_mapController.camera.center.latitude,
        _mapController.camera.center.longitude);
    var client = http.Client();
    String url =
        '${widget.baseUri}/reverse?format=json&lat=${_mapController.camera.center.latitude}&lon=${_mapController.camera.center.longitude}&zoom=18&addressdetails=1';

    var response = await client.get(Uri.parse(url), headers: {
      'User-Agent': widget.userAgentPackageName,
    });
    // var response = await client.post(Uri.parse(url));
    var decodedResponse =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<dynamic, dynamic>;
    String displayName = decodedResponse['display_name'];
    return PickedData(center, displayName, decodedResponse["address"]);
  }
}

class OSMdata {
  final String displayname;
  final double lat;
  final double lon;
  OSMdata({required this.displayname, required this.lat, required this.lon});
  @override
  String toString() {
    return '$displayname, $lat, $lon';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OSMdata && other.displayname == displayname;
  }

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

/// Represents a Latitude and Longitude coordinate pair.
class LatLong {
  final double latitude;
  final double longitude;
  const LatLong(this.latitude, this.longitude);
}

/// Data returned when a location is picked.
class PickedData {
  /// The GPS coordinates of the picked location.
  final LatLong latLong;

  /// The full display name of the address.
  final String addressName;

  /// A map containing detailed address components (city, country, etc.).
  final Map<String, dynamic> address;

  PickedData(this.latLong, this.addressName, this.address);
}
