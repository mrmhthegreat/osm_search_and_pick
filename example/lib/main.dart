import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter OSM Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isReadOnly = false;
  bool _liveTracking = false;
  double _radius = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isReadOnly ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isReadOnly = !_isReadOnly;
              });
            },
            tooltip: 'Toggle Read-Only',
          ),
          IconButton(
            icon: Icon(_liveTracking ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              setState(() {
                _liveTracking = !_liveTracking;
              });
            },
            tooltip: 'Toggle Live Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _radius += 100;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              setState(() {
                if (_radius > 100) _radius -= 100;
              });
            },
          ),
        ],
      ),
      body: OpenStreetMapSearchAndPick(
        buttonTextStyle:
            const TextStyle(fontSize: 18, fontStyle: FontStyle.normal),
        buttonColor: Colors.blue,
        buttonText: 'Set Current Location',
        buttonBorderRadius: 10,
        buttonElevation: 5,
        initialZoom: 16,
        userAgentPackageName: 'com.example.osm_search_and_pick',
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        isReadOnly: _isReadOnly,
        liveTracking: _liveTracking,
        locationPinWidget: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin_circle, color: Colors.indigo, size: 50),
            Text('Me!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ],
        ),
        routingStyle: RoutingStyle(
          routeColor: Colors.deepPurple,
          routeWidth: 6.0,
          borderColor: Colors.deepPurple.withValues(alpha: 0.4),
          borderStrokeWidth: 3.0,
          startMarkerWidget: const Icon(Icons.flag_circle, color: Colors.green, size: 36),
          endMarkerWidget: const Icon(Icons.api, color: Colors.red, size: 36),
          intermediateMarkerWidget: const Icon(Icons.circle, color: Colors.amber, size: 24),
        ),
        routingPanelStyle: const RoutingPanelStyle(
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          primaryColor: Colors.deepPurpleAccent,
          borderRadius: 24.0,
        ),
        onRoutingStateChanged: (state) {
          debugPrint('Routing State: ${state.waypoints.length} waypoints, mode: ${state.travelMode.name}');
          if (state.result != null) {
            debugPrint('Distance: ${state.result!.formattedDistance}, ETA: ${state.result!.formattedDuration}');
          }
        },
        onMapCreated: (controller) {
          debugPrint('Map is fully created and ready!');
        },
        onLocationChanged: (position) {
          debugPrint('Live Track: ${position.latitude}, ${position.longitude} (Speed: ${position.speed})');
        },
        onMapMoved: (center) {
          debugPrint('Map Moved to: ${center.latitude}, ${center.longitude}');
        },
        onSearchStatusChanged: (isSearching) {
          debugPrint('Is searching: $isSearching');
        },
        initialCenter: const LatLong(-33.8688, 151.2093), // Sydney CBD
        zones: [
          ZoneData(
            center: const LatLong(-33.8688, 151.2093), // CBD
            radius: _radius,
            color: Colors.blue.withValues(alpha: 0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
            title: 'Blue Zone',
            detail: 'This is the blue zone area',
          ),
          ZoneData(
            center: const LatLong(-33.8732, 151.1998), // Darling Harbour
            radius: 50,
            color: Colors.red.withValues(alpha: 0.3),
            borderColor: Colors.red,
            borderStrokeWidth: 2,
            title: 'Red Zone',
            detail: 'A small red zone',
            detailWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Custom Zone UI',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
        pins: [
          PinData(
            latLong: const LatLong(-33.8568, 151.2153), // Opera House
            title: 'Custom Pin',
            detail: 'Tapped!',
            color: Colors.blue,
            detailWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4)
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Custom Detail',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('This is a custom widget!',
                      style: TextStyle(color: Colors.white, fontSize: 10)),
                ],
              ),
            ),
          ),
          PinData(
            latLong: const LatLong(-33.8523, 151.2108), // Harbour Bridge
            title: 'Fully Custom Pin Widget',
            detail: 'This is not an icon',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 24),
            ),
          ),
          PinData(
            latLong: const LatLong(-33.8731, 151.2113), // Hyde Park
            title: 'Standard Pin',
            detail: 'Tap to see more',
            color: Colors.red,
          ),
        ],
        routes: [
          RouteData(
            points: const [
              LatLong(-33.8688, 151.2093),
              LatLong(-33.8732, 151.1998),
              LatLong(-33.8568, 151.2153),
            ],
            color: Colors.red,
            strokeWidth: 4.0,
            isDotted: false,
          ),
        ],
        onPicked: (pickedData) {
          debugPrint(pickedData.latLong.latitude.toString());
          debugPrint(pickedData.latLong.longitude.toString());
          debugPrint(pickedData.address.toString());
          debugPrint(pickedData.addressName);
        },
        showRoutingButton: true,
        routingBaseUri: 'https://router.project-osrm.org',
      ),
    );
  }
}
