# OSM Search and Pick

A Flutter place search and location picker plugin that uses Open Street Map. It is completely free, easy to use, and highly customizable.

## Features

- 📍 **Pick location from map**: Interactive map for selecting precise coordinates.
- 🔍 **Search location by places**: Integrated search bar for finding addresses via Nominatim.
- 🚀 **Easy to use**: Minimal setup required to get started.
- 🎨 **Highly Customizable**: Change icons, colors, text styles, and more.
- 📱 **Platform Support**: Works on Android, iOS, and Web.

---

## Demo

![Demo](https://user-images.githubusercontent.com/69592754/179368498-fe392cdb-c321-46e8-ac4d-6b816e0a3758.png)

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
  osm_search_and_pick: ^0.2.0
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

### Advanced Implementation with Customization

```dart
OpenStreetMapSearchAndPick(
    initialCenter: LatLong(23, 89),
    buttonColor: Colors.blue,
    buttonText: 'Set Current Location',
    locationPinIcon: Icons.location_on,
    locationPinText: 'Store Location',
    hintText: 'Search for a store...',
    onPicked: (pickedData) {
      // Handle the picked data
      setState(() {
          selectedAddress = pickedData.addressName;
      });
    }
)
```

---

## Customization Options

| Property | Description | Default |
|----------|-------------|---------|
| `onPicked` | Callback function when a location is selected. | **Required** |
| `initialCenter` | Starting coordinates for the map. | User's current location |
| `buttonColor` | Color of the FABs and 'Set Location' button. | `Colors.blue` |
| `buttonText` | Text displayed on the 'Set Location' button. | 'Set Current Location' |
| `hintText` | Text displayed in the search bar. | 'Search Location' |
| `zoomInIcon` | Icon for zooming in. | `Icons.zoom_in_map` |
| `zoomOutIcon` | Icon for zooming out. | `Icons.zoom_out_map` |
| `currentLocationIcon` | Icon for tracking current location. | `Icons.my_location` |
| `locationPinIcon` | Icon for the center pin. | `Icons.location_on` |
| `locationPinText` | Label above the center pin. | 'Location' |

---

## Picked Data Object

The `onPicked` callback returns a `PickedData` object containing:

- `latLong`: Contains `latitude` and `longitude`.
- `addressName`: The full display name of the location.
- `address`: A `Map<String, dynamic>` containing detailed address parts (city, country, etc.).

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
