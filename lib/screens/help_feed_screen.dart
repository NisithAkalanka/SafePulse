import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'sos_system/alerts_hub_screen.dart'; // Add this line
import '../help/help_request.dart';
import '../theme/guardian_ui.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import '../services/help_offer_notification_service.dart';
import '../services/help_role_mode_service.dart';
import 'sos_system/main_menu_screen.dart';

class HelpFeedScreen extends StatefulWidget {
  const HelpFeedScreen({super.key});

  @override
  State<HelpFeedScreen> createState() => _HelpFeedScreenState();
}

class _HelpFeedScreenState extends State<HelpFeedScreen> {
  Position? _currentPosition;

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
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (_) {
      // Keep last known position if any.
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
    // Distance display disabled in UI.
    return '';
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

    return (
      tagColor: tagColor,
      markerColor: markerColor,
      statusLabel: statusLabel,
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

  Widget _buildEmptyHelpState(BuildContext context) {
    final g = GuardianTheme.of(context);
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
            color: g.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pull down to refresh. New help posts will show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: g.textSecondary,
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
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        // Only show requests that are NOT the user's own and have no active offer from someone else
        final requests = _sortedRequests(all)
            .where(
              (r) =>
                  !r.isMine &&
                  (r.helperUid == null || r.helperUid == currentUid),
            )
            .toList();
        final g = GuardianTheme.of(context);

        return Scaffold(
          backgroundColor: g.scaffoldBg,
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
            actions: [
              IconButton(
                tooltip: 'Switch to Requester mode',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  HelpRoleModeService.instance.setHelperMode(false);
                },
              ),
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  MainMenuScreen.showOverlay(context);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 108, 18, 24),
                decoration: BoxDecoration(
                  gradient: g.headerGradient,
                  borderRadius: const BorderRadius.only(
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
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: g.panelBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: g.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RefreshIndicator(
                      color: GuardianUi.redPrimary,
                      onRefresh: () async {
                        await _loadLocation();
                        await HelpRequestService.instance.refreshOnce();
                      },
                      child: requests.isEmpty
                          ? _buildEmptyHelpState(context)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                2,
                                16,
                                2,
                                90, // Adding bottom padding to scroll past navigation
                              ),
                              itemCount: requests.length,
                              itemBuilder: (context, index) {
                                return _featuredCard(context, requests[index]);
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

  Widget _featuredCard(BuildContext context, HelpRequest request) {
    const Color redPrimary = GuardianUi.redPrimary;
    final g = GuardianTheme.of(context);
    final s = _styleFor(request);

    Future<void> sendOffer() async {
      final ok = await HelpOfferNotificationService.instance
          .notifyRequesterAboutOffer(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Offer sent. Redirecting to Alerts Hub...'
                : 'Could not send offer notification. Please try again.',
          ),
        ),
      );

      if (ok) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AlertsHubScreen()),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: sendOffer,
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: g.listItemBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: g.chipBorder.withValues(alpha: 0.95),
                width: 1.6,
              ),
              boxShadow: g.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: GuardianUi.redTint,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: redPrimary.withValues(alpha: 0.20),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: redPrimary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        request.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: g.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        request.requesterName.isNotEmpty
                            ? request.requesterName
                            : request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: g.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: g.textSecondary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (request.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          request.description.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: g.textSecondary.withValues(alpha: 0.9),
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
                              color: const Color(
                                0xFF1E9E5A,
                              ).withValues(alpha: 0.12),
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
                              style: TextStyle(
                                fontSize: 13,
                                color: g.captionGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: g.captionGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgoLabel(request.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: g.captionGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (request.isUrgent)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: GuardianUi.redTint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: redPrimary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'Urgent',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: redPrimary,
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: redPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                        onPressed: sendOffer,
                        child: const Text('Offer Help'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
