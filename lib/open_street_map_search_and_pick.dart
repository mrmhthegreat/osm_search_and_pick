// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:osm_search_and_pick/models/lat_long.dart';
import 'package:osm_search_and_pick/models/osm_data.dart';
import 'package:osm_search_and_pick/models/picked_data.dart';
import 'package:osm_search_and_pick/models/zone_data.dart';
import 'package:osm_search_and_pick/models/pin_data.dart';
import 'package:osm_search_and_pick/models/route_data.dart';
import 'package:osm_search_and_pick/routing/routing_manager.dart';
import 'package:osm_search_and_pick/routing/routing_panel.dart';
import 'package:osm_search_and_pick/widgets/wide_button.dart';
import 'package:osm_search_and_pick/models/routing_style.dart';

export 'package:osm_search_and_pick/models/osm_data.dart';
export 'package:osm_search_and_pick/models/picked_data.dart';
export 'package:osm_search_and_pick/models/zone_data.dart';
export 'package:osm_search_and_pick/models/pin_data.dart';
export 'package:osm_search_and_pick/models/route_data.dart';
export 'package:osm_search_and_pick/models/lat_long.dart';
export 'package:osm_search_and_pick/routing/routing_manager.dart';
export 'package:osm_search_and_pick/routing/route_result.dart';
export 'package:osm_search_and_pick/models/routing_style.dart';

class OpenStreetMapSearchAndPick extends StatefulWidget {
  /// Callback triggered when a location is picked.
  final void Function(PickedData pickedData) onPicked;

  /// Optional fully custom widget to use for the main location pin.
  /// If provided, [locationPinIcon] and [locationPinIconColor] are ignored.
  final Widget? locationPinWidget;

  /// Defines the look and feel of the routing paths and markers.
  final RoutingStyle? routingStyle;

  /// Defines the look and feel of the routing bottom sheet panel.
  final RoutingPanelStyle? routingPanelStyle;

  /// Callback triggered whenever the routing state (distance, time, points) changes.
  final void Function(RoutingState state)? onRoutingStateChanged;

  /// Triggered after the map constructs, exposing the internal MapController.
  final void Function(MapController)? onMapCreated;

  /// Triggers repeatedly, delivering live Position updates if [liveTracking] is enabled.
  final void Function(Position)? onLocationChanged;

  /// Triggers after any map movement (drag/pan), returning the new map center.
  final void Function(LatLong)? onMapMoved;

  /// Triggers with [true] when search fetching starts, and [false] when it stops.
  final void Function(bool isSearching)? onSearchStatusChanged;

  /// If true, the map will continually focus on the user's location via [Geolocator.getPositionStream].
  final bool liveTracking;
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
  final LatLong? initialCenter;
  final double initialZoom;
  final double maxZoom;
  final double minZoom;
  final String tileUrlTemplate;
  final double buttonBorderRadius;
  final double buttonElevation;
  final bool showZoomButtons;
  final bool showCurrentLocationButton;
  final bool showSearchBar;
  final bool showSetLocationButton;
  final String userAgentPackageName;
  final Color backgroundColor;
  final List<ZoneData> zones;
  final List<PinData> pins;
  final bool isReadOnly;
  final List<RouteData> routes;
  final String? routingBaseUri;
  final bool showRoutingButton;
  final void Function(RouteResult result)? onRouteFetched;

  const OpenStreetMapSearchAndPick({
    super.key,
    required this.onPicked,
    this.zoomOutIcon = Icons.zoom_out_map,
    this.zoomInIcon = Icons.zoom_in_map,
    this.currentLocationIcon = Icons.my_location,
    this.buttonColor = Colors.blue,
    this.locationPinIconColor = Colors.blue,
    this.locationPinText = 'Location',
    this.locationPinTextStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
    this.hintText = 'Search Location',
    this.buttonTextStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
    this.backgroundColor = Colors.white,
    this.zones = const [],
    this.pins = const [],
    this.isReadOnly = false,
    this.routes = const [],
    this.routingBaseUri,
    this.showRoutingButton = false,
    this.onRouteFetched,
    this.routingStyle,
    this.routingPanelStyle,
    this.onRoutingStateChanged,
    this.onMapCreated,
    this.onLocationChanged,
    this.onMapMoved,
    this.onSearchStatusChanged,
    this.liveTracking = false,
    this.locationPinWidget,
  });

  @override
  State<OpenStreetMapSearchAndPick> createState() => _OpenStreetMapSearchAndPickState();
}

class _OpenStreetMapSearchAndPickState extends State<OpenStreetMapSearchAndPick> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<OSMdata> _options = [];
  Timer? _debounce;
  final http.Client _httpClient = http.Client();
  late Future<Position?> _latlongFuture;
  Object? _selectedElement;
  StreamSubscription? _mapEventSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  RoutingManager? _routingManager;
  bool _routingPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _mapEventSubscription = _mapController.mapEventStream.listen((event) async {
      if (event is MapEventMoveEnd) {
        if (widget.onMapMoved != null) {
          widget.onMapMoved!(LatLong(event.camera.center.latitude, event.camera.center.longitude));
        }
        await _reverseGeocode(event.camera.center.latitude, event.camera.center.longitude);
      }
    });
    _latlongFuture = _getCurrentPosition();
    if (widget.routingBaseUri != null) {
      _routingManager = RoutingManager(
        baseUri: widget.routingBaseUri!,
        userAgentPackageName: widget.userAgentPackageName,
        httpClient: _httpClient,
      );
      _routingManager!.addListener(_onRoutingStateChanged);
    }
    if (widget.liveTracking) {
      _startLiveTracking();
    }
  }

  void _startLiveTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (widget.onLocationChanged != null) {
        widget.onLocationChanged!(position);
      }
      if (mounted) {
        _mapController.move(LatLng(position.latitude, position.longitude), _mapController.camera.zoom);
      }
    });
  }

  void _onRoutingStateChanged() {
    final state = _routingManager?.state;
    if (state != null && widget.onRoutingStateChanged != null) {
      widget.onRoutingStateChanged!(state);
    }

    final result = state?.result;
    if (result != null) {
      widget.onRouteFetched?.call(result);
      try {
        final bounds = boundsFromPoints(result.points);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _debounce?.cancel();
    _mapEventSubscription?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _routingManager?.removeListener(_onRoutingStateChanged);
    _routingManager?.dispose();
    _httpClient.close();
    super.dispose();
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition();
      await _reverseGeocode(pos.latitude, pos.longitude);
      return pos;
    } catch (e) {
      if (kDebugMode) print('getCurrentPosition: $e');
      return null;
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final r = await _httpClient.get(
        Uri.parse('${widget.baseUri}/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1'),
        headers: {'User-Agent': widget.userAgentPackageName},
      );
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      if (mounted) setState(() { _searchController.text = d['display_name'] ?? 'Unknown'; });
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() => _options = []);
      }
      return;
    }
    if (widget.onSearchStatusChanged != null) widget.onSearchStatusChanged!(true);
    try {
      final r = await _httpClient.get(
        Uri.parse('${widget.baseUri}/search?q=${Uri.encodeComponent(query)}&format=json&polygon_geojson=1&addressdetails=1'),
        headers: {'User-Agent': widget.userAgentPackageName},
      );
      final decoded = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      if (mounted) {
        setState(() {
          _options = decoded.map((e) => OSMdata(
            displayname: e['display_name'] as String,
            lat: double.parse(e['lat'] as String),
            lon: double.parse(e['lon'] as String),
          )).toList();
        });
      }
    } catch (_) {}
    if (widget.onSearchStatusChanged != null) widget.onSearchStatusChanged!(false);
  }

  Future<PickedData> _pickData() async {
    final center = LatLong(_mapController.camera.center.latitude, _mapController.camera.center.longitude);
    try {
      final r = await _httpClient.get(
        Uri.parse('${widget.baseUri}/reverse?format=json&lat=${center.latitude}&lon=${center.longitude}&zoom=18&addressdetails=1'),
        headers: {'User-Agent': widget.userAgentPackageName},
      );
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map;
      return PickedData(center, d['display_name'] as String? ?? '', Map<String, dynamic>.from(d['address'] as Map? ?? {}));
    } catch (_) {
      return PickedData(center, _searchController.text, {});
    }
  }

  void _showPinRoutingMenu(PinData pin) {
    final rm = _routingManager;
    if (rm == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.symmetric(vertical: 8), width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        if (pin.title.isNotEmpty)
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(pin.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
        ListTile(leading: const Icon(Icons.trip_origin, color: Colors.green), title: const Text('Route from here'),
            onTap: () { Navigator.pop(context); rm.setStartFromPin(pin); setState(() => _routingPanelVisible = true); }),
        ListTile(leading: const Icon(Icons.location_on, color: Colors.red), title: const Text('Route to here'),
            onTap: () { Navigator.pop(context); rm.setEndFromPin(pin); setState(() => _routingPanelVisible = true); }),
        ListTile(leading: const Icon(Icons.add_location_alt, color: Colors.orange), title: const Text('Add as waypoint'),
            onTap: () { Navigator.pop(context); rm.addWaypoint(LatLng(pin.latLong.latitude, pin.latLong.longitude)); setState(() => _routingPanelVisible = true); }),
      ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(borderSide: BorderSide(color: widget.buttonColor));
    final focusBorder = OutlineInputBorder(borderSide: BorderSide(color: widget.buttonColor, width: 3.0));
    final rm = _routingManager;
    final rs = rm?.state ?? const RoutingState();
    final rStyle = widget.routingStyle ?? const RoutingStyle();

    return FutureBuilder<Position?>(
      future: _latlongFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        LatLng? mapCentre;
        if (widget.initialCenter != null) {
          mapCentre = LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude);
        } else if (snapshot.hasData && snapshot.data != null) {
          mapCentre = LatLng(snapshot.data!.latitude, snapshot.data!.longitude);
        }

        return SafeArea(child: Stack(children: [
          Positioned.fill(child: FlutterMap(
            options: MapOptions(
              initialCenter: mapCentre ?? const LatLng(0, 0),
              initialZoom: widget.initialZoom, maxZoom: widget.maxZoom, minZoom: widget.minZoom,
              onMapReady: () {
                if (widget.onMapCreated != null) widget.onMapCreated!(_mapController);
              },
              onTap: (rm != null && rm.isPickingMode) ? (_, ll) => rm.addWaypointFromTap(ll) : null,
            ),
            mapController: _mapController,
            children: [
              TileLayer(urlTemplate: widget.tileUrlTemplate, userAgentPackageName: widget.userAgentPackageName, tileProvider: NetworkTileProvider()),
              CircleLayer(circles: widget.zones.map((e) => CircleMarker(point: LatLng(e.center.latitude, e.center.longitude), radius: e.radius, useRadiusInMeter: true, color: e.color, borderColor: e.borderColor, borderStrokeWidth: e.borderStrokeWidth)).toList()),
              PolylineLayer(polylines: [
                ...widget.routes.map((r) => Polyline(points: r.points.map((p) => LatLng(p.latitude, p.longitude)).toList(), color: r.color, strokeWidth: r.strokeWidth, pattern: r.isDotted ? const StrokePattern.dotted() : const StrokePattern.solid())),
                if (rs.result != null) Polyline(points: rs.result!.points, color: rStyle.routeColor, strokeWidth: rStyle.routeWidth, borderColor: rStyle.borderColor, borderStrokeWidth: rStyle.borderStrokeWidth),
              ]),
              MarkerLayer(markers: [
                ...rs.waypoints.asMap().entries.map((entry) {
                  final isStart = entry.key == 0;
                  final isEnd = entry.key == rs.waypoints.length - 1 && rs.waypoints.length > 1;
                  Widget child;
                  if (isStart) {
                    child = rStyle.startMarkerWidget ?? Icon(Icons.trip_origin, color: Colors.green, size: 20);
                  } else if (isEnd) {
                    child = rStyle.endMarkerWidget ?? Icon(Icons.location_on, color: Colors.red, size: 32);
                  } else {
                    child = rStyle.intermediateMarkerWidget ?? Icon(Icons.circle, color: Colors.orange, size: 20);
                  }
                  return Marker(point: entry.value, width: 36, height: 36, alignment: Alignment.bottomCenter, child: child);
                }),
                ...widget.pins.map((e) => Marker(
                  key: ObjectKey(e), point: LatLng(e.latLong.latitude, e.latLong.longitude),
                  alignment: Alignment.bottomCenter, width: 150, height: 150,
                  child: GestureDetector(
                    onTap: () => setState(() { _selectedElement = _selectedElement == e ? null : e; e.onTap?.call(); }),
                    onLongPress: rm != null ? () => _showPinRoutingMenu(e) : null,
                    child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (_selectedElement == e) Flexible(child: e.detailWidget ?? Column(mainAxisSize: MainAxisSize.min, children: [
                        if (e.title.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
                        if (e.detail.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(4)), child: Text(e.detail, style: const TextStyle(color: Colors.black, fontSize: 8), overflow: TextOverflow.ellipsis)),
                      ])),
                      e.child ?? Icon(e.icon, color: e.color, size: 30),
                    ]),
                  ),
                )),
                ...widget.zones.map((e) => Marker(
                  key: ObjectKey(e), point: LatLng(e.center.latitude, e.center.longitude),
                  alignment: Alignment.center, width: 120, height: 120,
                  child: GestureDetector(onTap: () => setState(() { _selectedElement = _selectedElement == e ? null : e; e.onTap?.call(); }),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (_selectedElement == e) Flexible(child: e.detailWidget ?? Column(mainAxisSize: MainAxisSize.min, children: [
                        if (e.title.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)), child: Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 10))),
                        if (e.detail.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(4)), child: Text(e.detail, style: const TextStyle(color: Colors.black, fontSize: 8))),
                      ])),
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: e.borderColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)])),
                    ]),
                  ),
                )),
              ]),
            ],
          )),

          if (rm != null && rm.isPickingMode)
            Positioned(top: 60, left: 0, right: 0, child: IgnorePointer(child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
              child: Text(rs.hasStart ? 'Tap map to set end point' : 'Tap map to set start point', style: const TextStyle(color: Colors.white, fontSize: 13)),
            )))),

          if (!widget.isReadOnly && !_routingPanelVisible) Positioned.fill(child: IgnorePointer(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.locationPinText, style: widget.locationPinTextStyle, textAlign: TextAlign.center),
            Padding(padding: const EdgeInsets.only(bottom: 50), child: widget.locationPinWidget ?? Icon(widget.locationPinIcon, size: 50, color: widget.locationPinIconColor)),
          ])))),

          if (widget.showZoomButtons) Positioned(bottom: _routingPanelVisible ? 320 : 180, right: 5, child: FloatingActionButton(heroTag: 'osm_zi', mini: true, backgroundColor: widget.buttonColor, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), child: Icon(widget.zoomInIcon, color: widget.buttonTextColor, size: 20))),
          if (widget.showZoomButtons) Positioned(bottom: _routingPanelVisible ? 270 : 130, right: 5, child: FloatingActionButton(heroTag: 'osm_zo', mini: true, backgroundColor: widget.buttonColor, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), child: Icon(widget.zoomOutIcon, color: widget.buttonTextColor, size: 20))),
          if (widget.showCurrentLocationButton) Positioned(bottom: _routingPanelVisible ? 220 : 80, right: 5, child: FloatingActionButton(heroTag: 'osm_loc', mini: true, backgroundColor: widget.buttonColor, onPressed: () async {
            if (mapCentre != null) { _mapController.move(mapCentre, _mapController.camera.zoom); }
            else { try { final pos = await Geolocator.getCurrentPosition(); _mapController.move(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom); } catch (_) {} }
          }, child: Icon(widget.currentLocationIcon, color: widget.buttonTextColor, size: 20))),

          if (widget.showRoutingButton && rm != null)
            Positioned(bottom: _routingPanelVisible ? 175 : 80, left: 5, child: FloatingActionButton(
              heroTag: 'osm_rt', backgroundColor: widget.buttonColor,
              onPressed: () => setState(() => _routingPanelVisible = !_routingPanelVisible),
              child: rs.isFetching
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: widget.buttonTextColor, strokeWidth: 2))
                  : Icon(_routingPanelVisible ? Icons.close : Icons.alt_route, color: widget.buttonTextColor),
            )),

          if (widget.showSearchBar && !widget.isReadOnly)
            Positioned(top: 0, left: 0, right: 0, child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: widget.backgroundColor, borderRadius: BorderRadius.circular(5)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _searchController, focusNode: _focusNode,
                  decoration: InputDecoration(hintText: widget.hintText, border: inputBorder, focusedBorder: focusBorder,
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _options = []); }) : null),
                  onChanged: (v) { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 600), () => _search(v)); },
                ),
                if (_options.isNotEmpty) ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: _options.length > 5 ? 5 : _options.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(_options[i].displayname, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${_options[i].lat.toStringAsFixed(5)}, ${_options[i].lon.toStringAsFixed(5)}'),
                    onTap: () { _mapController.move(LatLng(_options[i].lat, _options[i].lon), 15.0); _focusNode.unfocus(); setState(() => _options = []); },
                  ),
                ),
              ]),
            )),

          if (widget.showSetLocationButton && !widget.isReadOnly && !_routingPanelVisible)
            Positioned(bottom: 0, left: 0, right: 0, child: Center(child: Padding(padding: const EdgeInsets.all(8.0), child: WideButton(
              widget.buttonText, textStyle: widget.buttonTextStyle, height: widget.buttonHeight, width: widget.buttonWidth,
              onPressed: () async { final v = await _pickData(); widget.onPicked(v); },
              backgroundColor: widget.buttonColor, foregroundColor: widget.buttonTextColor,
              borderRadius: widget.buttonBorderRadius, elevation: widget.buttonElevation,
            )))),

          if (rm != null && _routingPanelVisible)
            Positioned(bottom: 0, left: 0, right: 0, child: RoutingPanel(
              state: rs,
              style: widget.routingPanelStyle,
              onModeChanged: (m) => rm.setTravelMode(m),
              onRemoveWaypoint: (i) => rm.removeWaypoint(i),
              onAddStop: () => rm.startPicking(),
              onClear: () { rm.clear(); setState(() => _routingPanelVisible = false); },
              onPickStart: () { final c = _mapController.camera.center; rm.addWaypointFromTap(c); },
              onPickEnd: () => rm.startPicking(),
            )),
        ]));
      },
    );
  }
}