# OSM Search and Pick

A Flutter place search and location picker plugin that uses Open Street Map. It is completely free, easy to use, and highly customizable.

## Features

- 📍 **Pick location from map**: Interactive map for selecting precise coordinates.
- 🔍 **Search location by places**: Integrated search bar for finding addresses via Nominatim.
- 🚀 **Easy to use**: Minimal setup required to get started.
- 🎨 **Highly Customizable**: Change icons, colors, text styles, and more.
- ⭕ **Zones Support**: Draw multiple circles with custom radius (**meters**), color and borders.
- 📌 **Multiple Pins**: Add multiple markers with custom icons, titles, and details.
- 👆 **Interactive Markers**: Markers and zones can show details on tap with custom designed widgets.
- 👁️ **Preview Mode**: Use the map in read-only mode for viewing only.
- 📱 **Platform Support**: Works on Android, iOS, and Web.

---

### Picker Mode
![Picker Mode](screenshots/DEMO%20WITH%20PICKER.png)

### Read-Only Mode
![Read-Only Mode](screenshots/DEMO%20READ%20ONLY.png)

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

## Customization Options

| Property | Description | Default |
|----------|-------------|---------|
| `onPicked` | Callback function when a location is selected. | **Required** |
| `initialCenter` | Starting coordinates for the map. | User's current location |
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
| `zones` | List of `ZoneData` to draw circles on the map. | `[]` |
| `pins` | List of `PinData` to draw custom markers. | `[]` |

---

## Picked Data Object

The `onPicked` callback returns a `PickedData` object containing:

- `latLong`: Contains `latitude` and `longitude`.
- `addressName`: The full display name of the location.
- `address`: A `Map<String, dynamic>` containing detailed address parts (city, country, etc.).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
