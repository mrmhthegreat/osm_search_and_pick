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

class OpenStreetMapSearchAndPick extends StatefulWidget {
  final void Function(PickedData pickedData) onPicked;
  final IconData zoomInIcon;
  final IconData zoomOutIcon;
  final IconData currentLocationIcon;
  final IconData locationPinIcon;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color locationPinIconColor;
  final String locationPinText;
  final TextStyle locationPinTextStyle;
  final String buttonText;
  final String hintText;
  final double buttonHeight;
  final double buttonWidth;
  final TextStyle buttonTextStyle;
  final String baseUri;

  const OpenStreetMapSearchAndPick({
    Key? key,
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
  }) : super(key: key);

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
    double latitude = _mapController.center.latitude;
    double longitude = _mapController.center.longitude;
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }
    String url =
        '${widget.baseUri}/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1';

    var response = await client.get(Uri.parse(url));
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

    var response = await client.get(Uri.parse(url));
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

          var response = await client.get(Uri.parse(url));
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
        }
        return SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: MapOptions(
                      center: mapCentre, zoom: 15.0, maxZoom: 18, minZoom: 6),
                  mapController: _mapController,
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
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
              Positioned(
                bottom: 180,
                right: 5,
                child: FloatingActionButton(
                  heroTag: 'btn1',
                  backgroundColor: widget.buttonColor,
                  onPressed: () {
                    _mapController.move(
                        _mapController.center, _mapController.zoom + 1);
                  },
                  child: Icon(
                    widget.zoomInIcon,
                    color: widget.buttonTextColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: 5,
                child: FloatingActionButton(
                  heroTag: 'btn2',
                  backgroundColor: widget.buttonColor,
                  onPressed: () {
                    _mapController.move(
                        _mapController.center, _mapController.zoom - 1);
                  },
                  child: Icon(
                    widget.zoomOutIcon,
                    color: widget.buttonTextColor,
                  ),
                ),
              ),
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
                          _mapController.zoom);
                    } else {
                      _mapController.move(
                          LatLng(50.5, 30.51), _mapController.zoom);
                    }
                    setNameCurrentPos();
                  },
                  child: Icon(
                    widget.currentLocationIcon,
                    color: widget.buttonTextColor,
                  ),
                ),
              ),
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
                                var response = await client.get(Uri.parse(url));
                                // var response = await client.post(Uri.parse(url));
                                var decodedResponse =
                                    jsonDecode(utf8.decode(response.bodyBytes))
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
    LatLong center = LatLong(
        _mapController.center.latitude, _mapController.center.longitude);
    var client = http.Client();
    String url =
        '${widget.baseUri}/reverse?format=json&lat=${_mapController.center.latitude}&lon=${_mapController.center.longitude}&zoom=18&addressdetails=1';

    var response = await client.get(Uri.parse(url));
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

class LatLong {
  final double latitude;
  final double longitude;
  const LatLong(this.latitude, this.longitude);
}

class PickedData {
  final LatLong latLong;
  final String addressName;
  final Map<String, dynamic> address;

  PickedData(this.latLong, this.addressName, this.address);
}
