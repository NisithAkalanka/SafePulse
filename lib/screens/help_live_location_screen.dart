import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/guardian_ui.dart';

class _SlitLocation {
  final String key;
  final String label;
  final double lat;
  final double lng;

  const _SlitLocation({
    required this.key,
    required this.label,
    required this.lat,
    required this.lng,
  });
}

class HelpLiveLocationScreen extends StatefulWidget {
  final String title;
  final String locationName;
  final double? lat;
  final double? lng;
  final String? creatorUid;

  const HelpLiveLocationScreen({
    super.key,
    required this.title,
    required this.locationName,
    required this.lat,
    required this.lng,
    this.creatorUid,
  });

  @override
  State<HelpLiveLocationScreen> createState() => _HelpLiveLocationScreenState();
}

class _HelpLiveLocationScreenState extends State<HelpLiveLocationScreen> {
  static const List<_SlitLocation> _locations = [
    _SlitLocation(key: 'main_gate', label: 'Main Gate', lat: 6.9149, lng: 79.9736),
    _SlitLocation(key: 'library', label: 'Library', lat: 6.9154, lng: 79.9731),
    _SlitLocation(key: 'auditorium', label: 'Auditorium', lat: 6.9142, lng: 79.9742),
    _SlitLocation(key: 'canteen', label: 'Canteen', lat: 6.9144, lng: 79.9729),
    _SlitLocation(key: 'car_park', label: 'Car Park', lat: 6.9152, lng: 79.9730),
    _SlitLocation(key: 'engineering_building', label: 'Engineering Building', lat: 6.9153, lng: 79.9734),
    _SlitLocation(key: 'business_school', label: 'Business School', lat: 6.9150, lng: 79.9732),
    _SlitLocation(key: 'juice_bar', label: 'Juice Bar', lat: 6.9149, lng: 79.9731),
    _SlitLocation(key: 'playground', label: 'Playground', lat: 6.9147, lng: 79.9730),
    _SlitLocation(key: 'birdnest', label: 'Bird Nest', lat: 6.9148, lng: 79.9732),
    _SlitLocation(key: 'william_angliss', label: 'William Angliss', lat: 6.9151, lng: 79.9735),
    _SlitLocation(key: 'main_building', label: 'Main Building', lat: 6.9147, lng: 79.9733),
    _SlitLocation(key: 'new_building_block', label: 'New Building/Block', lat: 6.9150, lng: 79.9729),
    _SlitLocation(key: 'new_building_g_block', label: 'New Building/G Block', lat: 6.9151, lng: 79.9727),
    _SlitLocation(key: 'other', label: 'Other', lat: 6.9148, lng: 79.9733),
  ];

  static const String _assetMapPath = 'assets/images/sliit_map.png';

  late double _selectedLat;
  late double _selectedLng;
  late String _selectedLabel;

  String? _phoneNumber;
  bool _loadingPhone = false;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.lat ?? 0;
    _selectedLng = widget.lng ?? 0;
    _selectedLabel = widget.locationName;

    if (_selectedLat == 0 || _selectedLng == 0) {
      // Fallback to the first known SLIIT coordinate.
      _selectedLat = _locations.first.lat;
      _selectedLng = _locations.first.lng;
      _selectedLabel = _locations.first.label;
    } else {
      // If the passed coords match a known campus spot, show its label.
      final nearest = _nearestLocation(_selectedLat, _selectedLng);
      if (nearest != null) {
        _selectedLabel = nearest.label;
      }
    }

    _loadPhoneIfNeeded();
  }

  Future<void> _loadPhoneIfNeeded() async {
    if (widget.creatorUid == null || widget.creatorUid!.isEmpty) return;
    setState(() {
      _loadingPhone = true;
    });
    try {
      final ds = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.creatorUid)
          .get();
      final phoneRaw = ds.data()?['phone']?.toString().trim();
      if (!mounted) return;
      setState(() {
        _phoneNumber = phoneRaw;
        _loadingPhone = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phoneNumber = null;
        _loadingPhone = false;
      });
    }
  }

  String? _normalizePhoneForTel(String? raw) {
    if (raw == null) return null;
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('0')) {
      // Sri Lanka: 0xxxxxxxxxx -> +94xxxxxxxxx
      return '+94${digits.substring(1)}';
    }
    if (digits.startsWith('+')) return digits;
    // 9xxxxxxxxx -> +94xxxxxxxxx
    if (!digits.startsWith('94') && digits.startsWith('7') && digits.length >= 9) {
      return '+94$digits';
    }
    if (digits.startsWith('94')) return '+$digits';
    return digits;
  }

  Future<void> _dial(String raw) async {
    final p = _normalizePhoneForTel(raw);
    if (p == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$p');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start the call.')),
      );
    }
  }

  Future<void> _openDialPad() async {
    final initial = _normalizePhoneForTel(_phoneNumber) ?? '';
    String current = initial;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final g = GuardianTheme.of(ctx);
            return AlertDialog(
              backgroundColor: g.panelBg,
              title: Text('Call', style: TextStyle(color: g.textPrimary)),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: g.figmaFieldFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: g.figmaFieldBorder),
                      ),
                      child: Text(
                        current.isEmpty ? 'Enter number' : current,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: g.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _padBtn(ctx, '*', setStateDialog, () => current += '*'),
                        _padBtn(ctx, '0', setStateDialog, () => current += '0'),
                        _padBtn(ctx, '#', setStateDialog, () => current += '#'),
                        _padBtn(ctx, '1', setStateDialog, () => current += '1'),
                        _padBtn(ctx, '2', setStateDialog, () => current += '2'),
                        _padBtn(ctx, '3', setStateDialog, () => current += '3'),
                        _padBtn(ctx, '4', setStateDialog, () => current += '4'),
                        _padBtn(ctx, '5', setStateDialog, () => current += '5'),
                        _padBtn(ctx, '6', setStateDialog, () => current += '6'),
                        _padBtn(ctx, '7', setStateDialog, () => current += '7'),
                        _padBtn(ctx, '8', setStateDialog, () => current += '8'),
                        _padBtn(ctx, '9', setStateDialog, () => current += '9'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setStateDialog(() {
                              if (current.isNotEmpty) current = current.substring(0, current.length - 1);
                            });
                          },
                          icon: const Icon(Icons.backspace_rounded),
                          label: const Text('Del'),
                        ),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() => current = '');
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _dial(current);
                  },
                  child: const Text('Call'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _padBtn(
    BuildContext context,
    String label,
    void Function(VoidCallback fn) setStateDialog,
    VoidCallback addFn,
  ) {
    final g = GuardianTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setStateDialog(addFn);
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: g.figmaFieldFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: g.figmaFieldBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: g.textPrimary,
          ),
        ),
      ),
    );
  }


  _SlitLocation? _nearestLocation(double lat, double lng) {
    _SlitLocation? best;
    double bestDist = double.infinity;
    for (final l in _locations) {
      final d = Geolocator.distanceBetween(lat, lng, l.lat, l.lng);
      if (d < bestDist) {
        bestDist = d;
        best = l;
      }
    }
    // Only snap if we're close enough (meters).
    if (bestDist < 120) return best;
    return null;
  }

  (double x, double y) _latLngToMapXY({
    required double lat,
    required double lng,
    required double w,
    required double h,
  }) {
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final l in _locations) {
      minLat = minLat < l.lat ? minLat : l.lat;
      maxLat = maxLat > l.lat ? maxLat : l.lat;
      minLng = minLng < l.lng ? minLng : l.lng;
      maxLng = maxLng > l.lng ? maxLng : l.lng;
    }

    final nx = (lng - minLng) / (maxLng - minLng);
    final ny = (lat - minLat) / (maxLat - minLat);

    // y: map image origin is top-left; lat increases upwards => invert.
    final x = nx.clamp(0.0, 1.0) * w;
    final y = (1 - ny).clamp(0.0, 1.0) * h;
    return (x, y);
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_selectedLat,$_selectedLng',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  Future<void> _useCurrentGps() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please allow location permission.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _selectedLat = pos.latitude;
        _selectedLng = pos.longitude;
        _selectedLabel = 'Current location';
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    return Scaffold(
      backgroundColor: g.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: g.panelBg,
        foregroundColor: g.textPrimary,
        title: Text(
          'Track Live Location',
          style: TextStyle(
            color: g.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: g.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: g.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: Text(
                            'Use my GPS',
                            style: TextStyle(color: g.textPrimary),
                          ),
                          backgroundColor: g.listItemBg,
                          side: BorderSide(color: g.chipBorder),
                          onPressed: _useCurrentGps,
                        ),
                        ..._locations.map((l) {
                          final selected = _selectedLabel == l.label;
                          return ActionChip(
                            label: Text(
                              l.label,
                              style: TextStyle(
                                color: selected
                                    ? GuardianUi.redPrimary
                                    : g.textPrimary,
                              ),
                            ),
                            backgroundColor: selected
                                ? GuardianUi.redPrimary.withValues(alpha: 0.2)
                                : g.listItemBg,
                            side: BorderSide(
                              color: selected
                                  ? GuardianUi.redPrimary
                                  : g.chipBorder,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedLat = l.lat;
                                _selectedLng = l.lng;
                                _selectedLabel = l.label;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        final marker = _latLngToMapXY(
                          lat: _selectedLat,
                          lng: _selectedLng,
                          w: w,
                          h: h,
                        );
                        return Stack(
                          children: [
                            Center(
                              child: Image.asset(
                                _assetMapPath,
                                width: w,
                                height: h,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              left: marker.$1 - 18,
                              top: marker.$2 - 36,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.redAccent,
                                size: 48,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: g.panelBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: g.chipBorder),
                    ),
                    child: Text(
                      '$_selectedLabel\nLat: ${_selectedLat.toStringAsFixed(5)}  Lng: ${_selectedLng.toStringAsFixed(5)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: g.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: g.panelBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  offset: const Offset(0, -6),
                  color: Colors.black.withValues(alpha: g.isDark ? 0.35 : 0.04),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openMaps,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Open in Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadingPhone ? null : _openDialPad,
                    icon: const Icon(Icons.phone_rounded),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
