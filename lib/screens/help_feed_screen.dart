import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
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
                            creatorUid: request.creatorUid,
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
      requesterName: r.requesterName.isNotEmpty ? r.requesterName : 'Requester',
      title: r.title,
      locationName: r.locationName,
      lat: r.lat ?? 0,
      lng: r.lng ?? 0,
      isUrgent: r.isUrgent,
      isMine: r.isMine,
      postedAt: r.createdAt,
      neededAt: r.neededAt,
      creatorUid: r.creatorUid,
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

        const Color redPrimary = Color(0xFFD32F2F);

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8B1A1A), Color(0xFF6B1515), Color(0xFF671111)],
                  ),
                ),
              ),
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 8, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                                onPressed: () {
                                  // If this page was opened via navigation stack, go back.
                                  // Otherwise, fallback to Help screen.
                                  final didPop = Navigator.of(context).canPop();
                                  if (didPop) {
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const HelpScreen()),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Help Nearby',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          if (_loadingLocation)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.my_location_rounded, size: 24, color: Colors.white),
                              onPressed: _loadLocation,
                              tooltip: 'Refresh location',
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          _filterChip('All', 0, redPrimary),
                          _filterChip('Urgent', 1, redPrimary),
                          _filterChip('Nearby', 2, redPrimary),
                          _filterChip('My Requests', 3, redPrimary),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: requests.length,
                        itemBuilder: (context, index) {
                          final request = requests[index];
                          final isFeatured = index == 0 && _selectedFilter != 3;
                          if (isFeatured) {
                            return _featuredCard(request, redPrimary);
                          }
                          return _compactCard(request, redPrimary);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, int index, Color redPrimary) {
    final bool isSelected = _selectedFilter == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedFilter = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? redPrimary : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featuredCard(_HelpRequest request, Color redPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: redPrimary.withOpacity(0.12),
                  child: Icon(Icons.person_rounded, color: redPrimary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.requesterName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.place_rounded, size: 16, color: redPrimary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.locationName,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _distanceLabel(request),
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.send_rounded, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Posted ${_timeAgoLabel(request.postedAt)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 14, color: redPrimary.withOpacity(0.75)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Needed ${DateFormat.yMMMd().add_jm().format(request.neededAt)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (request.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: redPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: redPrimary.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Urgent',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: redPrimary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: redPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

  Widget _compactCard(_HelpRequest request, Color redPrimary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (request.tagColor ?? const Color(0xFFF5F5F7)).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handshake_rounded, size: 20, color: redPrimary),
          ),
          const SizedBox(width: 12),
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
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _distanceLabel(request),
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  request.requesterName,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  request.title,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF1A1D2E)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: request.markerColor ?? redPrimary),
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${_timeAgoLabel(request.postedAt)} · Need ${DateFormat.MMMd().add_jm().format(request.neededAt)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
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
  final String requesterName;
  final String title;
  final String locationName;
  final double lat;
  final double lng;
  final bool isUrgent;
  final bool isMine;
  final DateTime postedAt;
  final DateTime neededAt;
  final String? creatorUid;
  final Color? markerColor;
  final Color? tagColor;
  final String? statusLabel;

  const _HelpRequest({
    required this.category,
    required this.requesterName,
    required this.title,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.isUrgent,
    required this.isMine,
    required this.postedAt,
    required this.neededAt,
    this.creatorUid,
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

