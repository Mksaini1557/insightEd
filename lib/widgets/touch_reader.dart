import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TouchReader extends StatefulWidget {
  final Widget child;
  final FlutterTts tts;
  final bool enabled;

  const TouchReader({
    super.key,
    required this.child,
    required this.tts,
    this.enabled = true,
  });

  @override
  State<TouchReader> createState() => TouchReaderState();
}

class TouchReaderState extends State<TouchReader> {
  final List<_ZoneEntry> _zones = [];
  String? _currentLabel;

  static TouchReaderState? of(BuildContext context) {
    return context.findAncestorStateOfType<TouchReaderState>();
  }

  void registerZone(GlobalKey key, String label) {
    if (!_zones.any((z) => z.key == key)) {
      _zones.add(_ZoneEntry(key: key, label: label));
    }
  }

  void clearZones() {
    _zones.clear();
    _currentLabel = null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onPanUpdate: (details) => _checkZones(details.globalPosition),
      onPanEnd: (_) => _speakCurrent(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _checkZones(Offset globalPos) {
    String? hit;
    for (final zone in _zones) {
      final ctx = zone.key.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      try {
        final pos = box.localToGlobal(Offset.zero);
        final rect = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
        if (rect.contains(globalPos)) {
          hit = zone.label;
          break;
        }
      } catch (_) {}
    }

    if (hit != null && hit != _currentLabel) {
      _currentLabel = hit;
      HapticFeedback.lightImpact();
      widget.tts.speak(hit);
    }
  }

  void _speakCurrent() {
    if (_currentLabel != null) {
      widget.tts.speak(_currentLabel!);
    }
  }
}

class _ZoneEntry {
  final GlobalKey key;
  final String label;
  _ZoneEntry({required this.key, required this.label});
}

/// Widget that auto-registers with TouchReader for finger-slide to speak.
class TouchableZone extends StatefulWidget {
  final String label;
  final Widget child;

  const TouchableZone({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  State<TouchableZone> createState() => _TouchableZoneState();
}

class _TouchableZoneState extends State<TouchableZone> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reader = TouchReaderState.of(context);
      reader?.registerZone(_key, widget.label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      child: SizedBox(
        key: _key,
        child: widget.child,
      ),
    );
  }
}
