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
        initialCenter: const LatLong(25.1972, 55.2744),
        initialZoom: 16,
        userAgentPackageName: 'com.example.osm_search_and_pick',
        backgroundColor: Colors.blue.withOpacity(0.1),
        isReadOnly: _isReadOnly,
        zones: [
          ZoneData(
            center: const LatLong(25.1972, 55.2744),
            radius: _radius,
            color: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
            title: 'Blue Zone',
            detail: 'This is the blue zone area',
          ),
          ZoneData(
            center: const LatLong(25.1985, 55.2796),
            radius: 50,
            color: Colors.red.withOpacity(0.3),
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
            latLong: const LatLong(25.1960, 55.2730),
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
            latLong: const LatLong(25.1945, 55.2710),
            title: 'Standard Pin',
            detail: 'Tap to see more',
            color: Colors.red,
          ),
        ],
        onPicked: (pickedData) {
          debugPrint(pickedData.latLong.latitude.toString());
          debugPrint(pickedData.latLong.longitude.toString());
          debugPrint(pickedData.address.toString());
          debugPrint(pickedData.addressName);
        },
      ),
    );
  }
}
