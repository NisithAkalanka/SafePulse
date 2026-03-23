import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'sos_system/profile_screen.dart';
import '../help/help_request.dart';
import '../theme/guardian_ui.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import 'help_private_chat_screen.dart';
import 'help_live_location_screen.dart';

class HelpFeedScreen extends StatefulWidget {
  const HelpFeedScreen({super.key});

  @override
  State<HelpFeedScreen> createState() => _HelpFeedScreenState();
}

class _HelpFeedScreenState extends State<HelpFeedScreen> {
  Position? _currentPosition;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    // Realtime listener (single shared subscription).
    HelpRequestService.instance.startListening();
    // Pull latest from server so new posts appear immediately (stream can lag on cache).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HelpRequestService.instance.refreshOnce();
    });
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

  /// Newest posts first, then distance as tiebreaker.
  List<HelpRequest> _sortedRequests(List<HelpRequest> requests) {
    final copy = List<HelpRequest>.from(requests);
    copy.sort((a, b) {
      final byTime = b.createdAt.compareTo(a.createdAt);
      if (byTime != 0) {
        return byTime;
      }
      return _distanceMeters(a).compareTo(_distanceMeters(b));
    });
    return copy;
  }

  double _distanceMeters(HelpRequest r) {
    if (_currentPosition == null || r.lat == null || r.lng == null) {
      return 0;
    }
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      r.lat!,
      r.lng!,
    );
  }

  String _distanceLabel(HelpRequest request) {
    final meters = _distanceMeters(request);
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

  ({Color tagColor, Color markerColor, String? statusLabel}) _styleFor(
    HelpRequest r,
  ) {
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

    return (tagColor: tagColor, markerColor: markerColor, statusLabel: statusLabel);
  }

  void _showRequestAccepted(HelpRequest request) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                      foregroundColor: GuardianUi.redPrimary,
                      side: const BorderSide(color: GuardianUi.redPrimary),
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

  /// Matches [GuardianMapScreen] header glass card.
  Widget _buildHelpHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help Nearby',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Browse open requests around you and offer help when you can.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Matches [GuardianMapScreen] `_topInfoStrip` mini chips.
  Widget _buildHelpTopInfoStrip(int openCount) {
    return Row(
      children: [
        Expanded(
          child: _helpTopMiniChip(
            Icons.list_alt_rounded,
            openCount == 1 ? '1 open request' : '$openCount open requests',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _helpTopMiniChip(
            Icons.near_me_outlined,
            _currentPosition != null ? 'Location on' : 'Location off',
          ),
        ),
      ],
    );
  }

  Widget _helpTopMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHelpState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      children: [
        Icon(
          Icons.handshake_outlined,
          size: 56,
          color: GuardianUi.redPrimary.withOpacity(0.35),
        ),
        const SizedBox(height: 16),
        Text(
          'No open requests',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GuardianUi.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh. New help posts will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: GuardianUi.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HelpRequest>>(
      valueListenable: HelpRequestsStore.instance.requests,
      builder: (context, all, _) {
        final requests = _sortedRequests(all);

        return Scaffold(
          backgroundColor: GuardianUi.surface,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Help Nearby',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            actions: [
              if (_loadingLocation)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  onPressed: _loadLocation,
                  tooltip: 'Refresh location',
                ),
              const SizedBox(width: 6),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 108, 18, 24),
                decoration: const BoxDecoration(
                  gradient: GuardianUi.headerGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHelpHeaderCard(),
                    const SizedBox(height: 12),
                    _buildHelpTopInfoStrip(requests.length),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: GuardianUi.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RefreshIndicator(
                      color: GuardianUi.redPrimary,
                      onRefresh: () =>
                          HelpRequestService.instance.refreshOnce(),
                      child: requests.isEmpty
                          ? _buildEmptyHelpState()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                16,
                                14,
                                24,
                              ),
                              itemCount: requests.length,
                              itemBuilder: (context, index) {
                                return _featuredCard(requests[index]);
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featuredCard(HelpRequest request) {
    const Color redPrimary = GuardianUi.redPrimary;
    final s = _styleFor(request);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: GuardianUi.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                Container(
                  width: 4,
                  height: 52,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    color: s.tagColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: GuardianUi.redTint,
                  child: Icon(
                    Icons.person_rounded,
                    color: redPrimary,
                    size: 20,
                  ),
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
                          fontWeight: FontWeight.w900,
                          color: GuardianUi.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.requesterName.isNotEmpty
                            ? request.requesterName
                            : 'Requester',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: GuardianUi.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: GuardianUi.textPrimary,
                        ),
                      ),
                      if (request.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          request.description.trim(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: GuardianUi.textSecondary.withOpacity(0.9),
                          ),
                        ),
                      ],
                      if (s.statusLabel != null) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E9E5A).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              s.statusLabel!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E9E5A),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: redPrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.locationName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF747A86),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _distanceLabel(request),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF747A86),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: Color(0xFF747A86),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgoLabel(request.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF747A86),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 14,
                            color: redPrimary.withOpacity(0.85),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Needed ${DateFormat.yMMMd().add_jm().format(request.neededAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: GuardianUi.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: GuardianUi.redTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: redPrimary.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: redPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: redPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.4,
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
}
