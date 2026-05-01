import 'package:flutter/material.dart';
import 'package:osm_search_and_pick/routing/routing_manager.dart';
import 'package:osm_search_and_pick/models/routing_style.dart';

/// Bottom sheet panel that shows routing controls, summary, and turn-by-turn.
/// Designed to sit inside a [Stack] above the map.
class RoutingPanel extends StatefulWidget {
  final RoutingState state;
  final RoutingPanelStyle? style;
  final void Function(TravelMode) onModeChanged;
  final void Function(int index) onRemoveWaypoint;
  final VoidCallback onAddStop;
  final VoidCallback onClear;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const RoutingPanel({
    super.key,
    required this.state,
    this.style,
    required this.onModeChanged,
    required this.onRemoveWaypoint,
    required this.onClear,
    required this.onAddStop,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  State<RoutingPanel> createState() => _RoutingPanelState();
}

class _RoutingPanelState extends State<RoutingPanel> {
  bool _stepsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final rStyle = widget.style ?? const RoutingPanelStyle();
    final theme = Theme.of(context);
    final bgColor = rStyle.backgroundColor ?? theme.colorScheme.surface;
    final textColor = rStyle.textColor ?? theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(rStyle.borderRadius)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Icon(Icons.alt_route, size: 20, color: textColor),
                const SizedBox(width: 8),
                Text('Route',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                const Spacer(),
                // Travel mode selector
                ..._buildModeChips(s, rStyle, theme),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: textColor),
                  onPressed: widget.onClear,
                  tooltip: 'Clear route',
                ),
              ],
            ),
          ),

          // ── Waypoints list ───────────────────────────────────────────────
          _buildWaypointList(s, theme, textColor),

          // ── Action buttons ───────────────────────────────────────────────
          _buildActionRow(s, theme),

          // ── Loading / error ──────────────────────────────────────────────
          if (s.isFetching)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: rStyle.primaryColor ?? theme.colorScheme.primary)),
                  const SizedBox(width: 10),
                  Text('Finding best route…',
                      style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7))),
                ],
              ),
            ),

          if (s.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(s.error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // ── Route summary ────────────────────────────────────────────────
          if (s.result != null) ...[
            _buildRouteSummary(s, theme, rStyle, textColor),
            // Turn-by-turn expandable
            if (s.result!.steps.isNotEmpty) _buildStepsSection(s, theme, rStyle, textColor),
          ],

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode chips
  // ---------------------------------------------------------------------------

  List<Widget> _buildModeChips(RoutingState s, RoutingPanelStyle rStyle, ThemeData theme) {
    final primary = rStyle.primaryColor ?? theme.colorScheme.primary;
    final unselectedText = rStyle.textColor?.withValues(alpha: 0.6) ?? Colors.grey.shade600;
    
    return TravelMode.values.map((mode) {
      final selected = s.travelMode == mode;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: () => widget.onModeChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? primary
                    : (rStyle.textColor?.withValues(alpha: 0.2) ?? Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(mode.icon,
                    size: 14,
                    color: selected ? Colors.white : unselectedText),
                const SizedBox(width: 4),
                Text(mode.label,
                    style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white : unselectedText,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Waypoints
  // ---------------------------------------------------------------------------

  Widget _buildWaypointList(RoutingState s, ThemeData theme, Color textColor) {
    if (s.waypoints.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'Tap "Set start" or tap the map to begin routing.',
          style:
              TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.5)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: s.waypoints.asMap().entries.map((entry) {
          final i = entry.key;
          final pt = entry.value;
          final isStart = i == 0;
          final isEnd = i == s.waypoints.length - 1 && s.waypoints.length > 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isStart
                      ? Icons.trip_origin
                      : isEnd
                          ? Icons.location_on
                          : Icons.circle,
                  size: isEnd ? 20 : 16,
                  color: isStart
                      ? Colors.green
                      : isEnd
                          ? Colors.red
                          : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${pt.latitude.toStringAsFixed(5)}, '
                    '${pt.longitude.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 12, color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (s.waypoints.length > 1)
                  GestureDetector(
                    onTap: () => widget.onRemoveWaypoint(i),
                    child: Icon(Icons.close, size: 16, color: textColor.withValues(alpha: 0.5)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action row (pick / add stop)
  // ---------------------------------------------------------------------------

  Widget _buildActionRow(RoutingState s, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        children: [
          if (!s.hasStart)
            _chip(
              label: 'Set start',
              icon: Icons.trip_origin,
              color: Colors.green,
              onTap: widget.onPickStart,
            ),
          if (s.hasStart && !s.hasEnd)
            _chip(
              label: 'Set end',
              icon: Icons.location_on,
              color: Colors.red,
              onTap: widget.onPickEnd,
            ),
          if (s.isComplete)
            _chip(
              label: 'Add stop',
              icon: Icons.add_location_alt,
              color: Colors.orange,
              onTap: widget.onAddStop,
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Route summary card
  // ---------------------------------------------------------------------------

  Widget _buildRouteSummary(RoutingState s, ThemeData theme, RoutingPanelStyle rStyle, Color textColor) {
    final primary = rStyle.primaryColor ?? theme.colorScheme.primary;
    final result = s.result!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem(Icons.straighten, result.formattedDistance, 'Distance', primary, textColor),
          _divider(textColor),
          _summaryItem(Icons.access_time, result.formattedDuration, 'ETA', primary, textColor),
          _divider(textColor),
          _summaryItem(result.travelMode.icon, result.travelMode.label, 'Mode', primary, textColor),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color primary, Color textColor) {
    return Column(
      children: [
        Icon(icon, size: 16, color: primary),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: primary)),
        Text(label,
            style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _divider(Color textColor) => Container(
        height: 32,
        width: 1,
        color: textColor.withValues(alpha: 0.15),
      );

  // ---------------------------------------------------------------------------
  // Turn-by-turn steps
  // ---------------------------------------------------------------------------

  Widget _buildStepsSection(RoutingState s, ThemeData theme, RoutingPanelStyle rStyle, Color textColor) {
    final primary = rStyle.primaryColor ?? theme.colorScheme.primary;
    final steps = s.result!.steps;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle header
        InkWell(
          onTap: () => setState(() => _stepsExpanded = !_stepsExpanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                Icon(Icons.turn_right, size: 16, color: textColor.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  '${steps.length} turn${steps.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.8)),
                ),
                const Spacer(),
                Icon(
                  _stepsExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (_stepsExpanded)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: steps.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final step = steps[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.instruction,
                                style: TextStyle(fontSize: 13, color: textColor)),
                            if (step.distanceMetres > 0)
                              Text(step.formattedDistance,
                                  style: TextStyle(
                                      fontSize: 11, color: textColor.withValues(alpha: 0.5))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
