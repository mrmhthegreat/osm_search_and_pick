## 0.3.0

- Added support for multiple **Zones** (Circles) with custom radius, color, and borders.
- Added support for multiple custom **Pins** with icons, titles, and details.
- Added **Preview Mode** (`isReadOnly`) to use the map as a viewer without picker/search UI.
- Added custom **Background Color** for the search bar and results container.
- Supported **Dynamic Updates** for all map elements.
- **Improved Zones**: Radii now use **meters** (`useRadiusInMeter: true`) for accurate scaling.
- **Interactive Markers**: Pins and zones now support tap interactions to show/hide details.
- **Customizable Details**: Added `detailWidget`, `title`, and `detail` fields to `ZoneData` and `PinData` for flexible popup designs.

## 0.2.1

- Added custom `userAgentPackageName` in Http client and TileLayer to comply with OpenStreetMap Tile Usage Policy (Fixes 403 Forbidden errors).
- Added map customization properties: `initialZoom`, `minZoom`, `maxZoom`.
- Added ability to use custom tile servers via `tileUrlTemplate`.
- Added `borderRadius` and `elevation` properties to customize the main action button UI.
- Added visibility controls for UI elements: `showZoomButtons`, `showCurrentLocationButton`, `showSearchBar`, `showSetLocationButton`.
- General UI styling improvements.

## 0.2.0

- Upgraded dependencies to latest stable versions.
- Minimum Dart SDK updated to 3.4.4.
- Breaking changes: Migrated to `flutter_map` v8 (updated `MapOptions` and `MapController` usage).
- Modernized example app with Material 3 and `super_parameters`.
- Stability improvements and code cleanup.

## 0.1.1
- Original version.

## 0.1.0

- Huge customizations
- Bug fixes.
