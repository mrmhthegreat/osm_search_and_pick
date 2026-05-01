# OSM Search and Pick

A Flutter place search and location picker plugin that uses Open Street Map. It is completely free, easy to use, and highly customizable.

## Features

- 📍 **Pick location from map**: Interactive map for selecting precise coordinates.
- 🔍 **Search location by places**: Integrated search bar for finding addresses via Nominatim.
- 🚀 **Easy to use**: Minimal setup required to get started.
- 🎨 **Highly Customizable**: Change icons, colors, text styles, and completely inject your own widgets.
- 🗺️ **Dynamic OSRM Routing**: Render deep interactive routes with custom completely styled UI modes! 
- 🎯 **Continuous Live Tracking**: Follow mobile users dynamically via active GPS tracking modes.
- ⭕ **Zones Support**: Draw multiple circles with custom radius (**meters**), color and borders.
- 📌 **Multiple Pins**: Add multiple markers with custom icons, customized widgets, titles, and details.
- 👆 **Interactive Markers**: Markers and zones can show details on tap with custom designed widgets.
- 🎧 **Stream Event Listeners**: Easily listen to streams outputting precise user dragging, location limits, and UI statuses.
- 👁️ **Preview Mode**: Use the map in read-only mode for viewing only.
- 📱 **Platform Support**: Works on Android, iOS, and Web.

---

### Picker Mode
![Picker Mode](https://raw.githubusercontent.com/mrmhthegreat/osm_search_and_pick/refs/heads/main/screenshots/d.png)

### Read-Only Mode
![Read-Only Mode](https://raw.githubusercontent.com/mrmhthegreat/osm_search_and_pick/refs/heads/main/screenshots/f.png)


---

## Requirements

This package uses the [geolocator](https://pub.dev/packages/geolocator) package to get the user's current location. You **must** add the following permissions to your project.

### Android

Add the following to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

Add the following to your `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when open to show your current position on the map.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location when in the background to show your current position on the map.</string>
```

---

## Tile Usage Policy

> [!IMPORTANT]
> This package uses OpenStreetMap's public tile servers by default. These servers are **not** free for high-volume use. Please review the [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) to ensure your app complies. For production apps with high traffic, consider using a commercial tile provider or hosting your own tiles.

---

## Installation

Add `osm_search_and_pick` to your `pubspec.yaml`:

```yaml
dependencies:
  osm_search_and_pick: ^0.3.0
```

---

## Usage

### Simple Implementation

```dart
import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/open_street_map_search_and_pick.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OpenStreetMapSearchAndPick(
        onPicked: (pickedData) {
          print(pickedData.latLong.latitude);
          print(pickedData.latLong.longitude);
          print(pickedData.address);
          print(pickedData.addressName);
        },
      ),
    );
  }
}
```

```dart
OpenStreetMapSearchAndPick(
    initialCenter: LatLong(23, 89),
    buttonColor: Colors.blue,
    buttonText: 'Set Current Location',
    locationPinIcon: Icons.location_on,
    locationPinText: 'Store Location',
    backgroundColor: Colors.white,
    isReadOnly: false,
    zones: [
      ZoneData(
        center: LatLong(23, 89),
        radius: 500,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
        title: 'Work Zone',
        detail: 'Office building area',
      ),
    ],
    pins: [
      PinData(
        latLong: LatLong(23.1, 89.1),
        title: 'Delivery Point',
        color: Colors.red,
      ),
    ],
    onPicked: (pickedData) {
      // Handle the picked data
      setState(() {
          selectedAddress = pickedData.addressName;
      });
    }
)
```

### Interactive & Customizable Markers

Markers (Pins and Zone Centers) now support tap interactions. By default, tapping a marker reveals its title and detail. You can provide a `detailWidget` for a completely custom design.

```dart
PinData(
  latLong: LatLong(23.1, 89.1),
  title: 'Custom Pin',
  detailWidget: Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text('Custom UI', style: TextStyle(color: Colors.white)),
  ),
  onTap: () => print('Tapped!'),
)
```

You can entirely override the icon logic by passing a custom layout into the `PinData.child` property or completely redesign the central picker via `locationPinWidget`:

```dart
OpenStreetMapSearchAndPick(
    locationPinWidget: Icon(Icons.person_pin_circle, color: Colors.indigo, size: 50),
    pins: [
        PinData(
            latLong: LatLong(23.1, 89.1),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange),
              child: Icon(Icons.star, color: Colors.white, size: 24),
            ),
        ),
    ]
)
```

### OSRM Routing & Dynamic Panels

This package supports deep integration with OSRM (Open Source Routing Machine). To enable it, provide a base routing URL. Users can build their own routes by long-pressing points, or tapping custom marker bounds!

```dart
OpenStreetMapSearchAndPick(
    showRoutingButton: true,
    routingBaseUri: 'https://router.project-osrm.org',
    routingStyle: RoutingStyle(
        routeColor: Colors.deepPurple,
        routeWidth: 6.0,
        startMarkerWidget: Icon(Icons.flag_circle, color: Colors.green),
        endMarkerWidget: Icon(Icons.api, color: Colors.red),
    ),
    routingPanelStyle: RoutingPanelStyle( // Customize the Routing pop-up drawer perfectly!
        backgroundColor: Colors.black87,
        textColor: Colors.white,
    ),
    onRoutingStateChanged: (state) {
        if (state.result != null) {
            print('ETA: ${state.result!.formattedDuration}');
        }
    },
)
```

```dart
ZoneData(
  center: LatLong(23, 89),
  radius: 100,
  title: 'Safe Zone',
  detail: 'Authorized personnel only',
  detailWidget: Card(
    color: Colors.green,
    child: Padding(
      padding: EdgeInsets.all(8.0),
      child: Text('Protected Area', style: TextStyle(color: Colors.white)),
    ),
  ),
  onTap: () => print('Zone tapped!'),
)
```

> [!NOTE]
> The `radius` in `ZoneData` is now interpreted in **meters**.

### Preview (Read-Only) Mode

Disable search, center pin, and the "Set Location" button to use the map as a simple viewer.

```dart
OpenStreetMapSearchAndPick(
  isReadOnly: true,
  onPicked: (_) {}, // Required but not used in read-only mode
  zones: [...],
  pins: [...],
)
```

---

## Streaming Listeners & Continuous Tracking

Tap directly into maps streams without breaking integration by utilizing event listeners:

```dart
OpenStreetMapSearchAndPick(
  // Automatically pivots camera natively mapped to Geolocation GPS
  liveTracking: true, 

  // Fires continuous GPS output as they physically drive/walk
  onLocationChanged: (Position position) => print(position.speed),
  
  // Fires perfectly whenever the map camera physically resets stops
  onMapMoved: (LatLong center) => print("Dragged to $center"),
  
  // Exposes MapController for completely external triggering (ex: an external jump-to button)
  onMapCreated: (MapController controller) {},
  
  // Displays network fetching active states (great for triggering external loaders!)
  onSearchStatusChanged: (bool isSearching) {},
  //...
)
```

---

## Customization Options

| Property | Description | Default |
|----------|-------------|---------|
| `onPicked` | Callback function when a location is selected. | **Required** |
| `initialCenter` | Starting coordinates for the map. Strongly overrides hardware GPS on initialization! | User's current location |
| `initialZoom` | Initial zoom level of the map. | `15.0` |
| `maxZoom` | Maximum zoom level allowed. | `18.0` |
| `minZoom` | Minimum zoom level allowed. | `6.0` |
| `tileUrlTemplate` | Custom Tile Server URL template. | `'https://tile.openstreetmap.org/{z}/{x}/{y}.png'` |
| `userAgentPackageName` | Application package name. Useful for compliant usage of OpenStreetMap Tile servers. | `'osm_search_and_pick'` |
| `buttonColor` | Color of the FABs and 'Set Location' button. | `Colors.blue` |
| `buttonText` | Text displayed on the 'Set Location' button. | `'Set Current Location'` |
| `buttonBorderRadius` | Border radius for the 'Set Location' button. | `5.0` |
| `buttonElevation` | Elevation for the 'Set Location' button. | `2.0` |
| `hintText` | Text displayed in the search bar. | `'Search Location'` |
| `zoomInIcon` | Icon for zooming in. | `Icons.zoom_in_map` |
| `zoomOutIcon` | Icon for zooming out. | `Icons.zoom_out_map` |
| `currentLocationIcon` | Icon for tracking current location. | `Icons.my_location` |
| `locationPinTextStyle` | Text style for the label above the center pin. | `TextStyle(...)` |
| `locationPinText` | Label above the center pin. | `'Location'` |
| `showZoomButtons` | Whether to show zoom in/out buttons. | `true` |
| `showCurrentLocationButton` | Whether to show the current location button. | `true` |
| `showSearchBar` | Whether to show the search bar. | `true` |
| `showSetLocationButton` | Whether to show the main "Set Location" button. | `true` |
| `backgroundColor` | Background color for search bar and results. | `Colors.white` |
| `isReadOnly` | Enables read-only mode (hides picker/search UI). | `false` |
| `liveTracking` | Enables continuous camera snap-tracking of user GPS. | `false` |
| `locationPinWidget` | A completely custom widget to replace the stationary central pin cursor. | `null` |
| `zones` | List of `ZoneData` to draw circles on the map. | `[]` |
| `pins` | List of `PinData` to draw custom markers. | `[]` |
| `routingStyle` | Provides completely custom color rendering/theming of active map routes. | `null` |
| `routingPanelStyle` | Allows modifying completely the UI styling for the sliding Route drawer. | `null` |
| `onMapCreated` | Event Handler: Returns instance of MapController. | `null` |
| `onMapMoved` | Event Handler: Returns continuous updates of Map pan/drag limits. | `null` |
| `onLocationChanged` | Event Handler: Returns the explicit GPS device properties during Live Tracking. | `null` |
| `onSearchStatusChanged` | Event Handler: Updates true/false as network searches initiate. | `null` |
| `onRoutingStateChanged` | Event Handler: Emits live instances of generated Turn-by-Turn metrics. | `null` |

---

## Picked Data Object

The `onPicked` callback returns a `PickedData` object containing:

- `latLong`: Contains `latitude` and `longitude`.
- `addressName`: The full display name of the location.
- `address`: A `Map<String, dynamic>` containing detailed address parts (city, country, etc.).

---
### Demo A
![Demo A](https://raw.githubusercontent.com/mrmhthegreat/osm_search_and_pick/refs/heads/main/screenshots/a.png)

### Demo B
![Demo B](https://raw.githubusercontent.com/mrmhthegreat/osm_search_and_pick/refs/heads/main/screenshots/b.png)

### Demo C
![Demo C](https://raw.githubusercontent.com/mrmhthegreat/osm_search_and_pick/refs/heads/main/screenshots/c.png)



## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Keywords
Flutter Location Picker, OpenStreetMap, OSM, Flutter Map, Map Routing, OSRM, Nominatim, Place Search, Address Search, Live Tracking, Map Markers, Flutter Geolocation, Custom Map Pins, Flutter Maps Plugin, Location Selection, GPS Tracking.
