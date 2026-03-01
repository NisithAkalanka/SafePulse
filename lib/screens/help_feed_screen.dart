import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'help_screen.dart';
import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import 'help_private_chat_screen.dart';
import 'help_live_location_screen.dart';

class HelpFeedScreen extends StatefulWidget {
  const HelpFeedScreen({super.key});

  @override
  State<HelpFeedScreen> createState() => _HelpFeedScreenState();
}

class _HelpFeedScreenState extends State<HelpFeedScreen> {
  int _selectedFilter = 2; // 0 = All, 1 = Urgent, 2 = Nearby, 3 = My Requests
  Position? _currentPosition;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    } catch (_) {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  List<_HelpRequest> _filteredRequests(List<_HelpRequest> requests) {
    switch (_selectedFilter) {
      case 1:
        return requests.where((r) => r.isUrgent).toList();
      case 2:
        return [...requests]..sort(
            (a, b) => a.distanceMeters(_currentPosition).compareTo(
              b.distanceMeters(_currentPosition),
            ),
          );
      case 3:
        return requests.where((r) => r.isMine).toList();
      default:
        return requests;
    }
  }

  String _distanceLabel(_HelpRequest request) {
    final meters = request.distanceMeters(_currentPosition);
    if (meters <= 0) return 'Nearby';
    if (meters < 1000) {
      return '${meters.round()}m away';
    }
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)}km away';
  }

  String _timeAgoLabel(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Posted ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Posted ${diff.inHours}h ago';
    return 'Posted ${diff.inDays}d ago';
  }

  void _openCreateHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }

  void _showRequestAccepted(_HelpRequest request) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Request Accepted 🎉',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HelpPrivateChatScreen(
                            title: request.category,
                            subtitle: request.title,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Private Chat'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE0E0E6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HelpLiveLocationScreen(
                            title: request.title,
                            locationName: request.locationName,
                            lat: request.lat,
                            lng: request.lng,
                          ),
                        ),
                      );
                    },
                    child: const Text('Track Live Location'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _HelpRequest _toUiRequest(HelpRequest r) {
    final lower = r.category.toLowerCase();
    final Color tagColor;
    final Color markerColor;
    String? statusLabel;

    if (lower.contains('study')) {
      tagColor = const Color(0xFFE3F2FD);
      markerColor = Colors.redAccent;
    } else if (lower.contains('transport')) {
      tagColor = const Color(0xFFE8F5E9);
      markerColor = Colors.green;
      if (r.isUrgent) statusLabel = 'SOS';
    } else if (lower.contains('tech')) {
      tagColor = const Color(0xFFFFF3E0);
      markerColor = Colors.green;
    } else if (lower.contains('cash')) {
      tagColor = const Color(0xFFFFF8E1);
      markerColor = Colors.orangeAccent;
    } else {
      tagColor = const Color(0xFFF5F5F7);
      markerColor = Colors.redAccent;
    }

    return _HelpRequest(
      category: r.category,
      title: r.title,
      locationName: r.locationName,
      lat: r.lat ?? 0,
      lng: r.lng ?? 0,
      isUrgent: r.isUrgent,
      isMine: r.isMine,
      postedAt: r.createdAt,
      markerColor: markerColor,
      tagColor: tagColor,
      statusLabel: statusLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<HelpRequest>>(
      valueListenable: HelpRequestsStore.instance.requests,
      builder: (context, all, _) {
        final uiAll = all.map(_toUiRequest).toList();
        final requests = _filteredRequests(uiAll);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Help Nearby',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_loadingLocation)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.my_location_rounded, size: 20),
                          onPressed: _loadLocation,
                          tooltip: 'Refresh location',
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _filterChip('All', 0),
                      _filterChip('Urgent', 1),
                      _filterChip('Nearby', 2),
                      _filterChip('My Requests', 3),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final isFeatured = index == 0 && _selectedFilter != 3;

                      if (isFeatured) {
                        return _featuredCard(request);
                      }
                      return _compactCard(request);
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: _openCreateHelp,
            backgroundColor: const Color(0xFFFFD54F),
            elevation: 4,
            child: const Icon(Icons.add_rounded, color: Colors.black87),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, int index) {
    final bool isSelected = _selectedFilter == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilter = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? Colors.redAccent : const Color(0xFFE0E0E6),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.redAccent : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featuredCard(_HelpRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE0E0E6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.person, color: Colors.blueGrey, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.locationName,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _distanceLabel(request),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgoLabel(request.postedAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (request.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                onPressed: () => _showRequestAccepted(request),
                child: const Text('OFFER HELP'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactCard(_HelpRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: request.tagColor ?? const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.handshake_rounded, size: 18, color: Colors.redAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _distanceLabel(request),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  request.title,
                  style: const TextStyle(fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: request.markerColor ?? Colors.redAccent,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        request.locationName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (request.statusLabel != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          request.statusLabel!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      _timeAgoLabel(request.postedAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpRequest {
  final String category;
  final String title;
  final String locationName;
  final double lat;
  final double lng;
  final bool isUrgent;
  final bool isMine;
  final DateTime postedAt;
  final Color? markerColor;
  final Color? tagColor;
  final String? statusLabel;

  const _HelpRequest({
    required this.category,
    required this.title,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.isUrgent,
    required this.isMine,
    required this.postedAt,
    this.markerColor,
    this.tagColor,
    this.statusLabel,
  });

  double distanceMeters(Position? current) {
    if (current == null) return 0;
    return Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      lat,
      lng,
    );
  }
}

