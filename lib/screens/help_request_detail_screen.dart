import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'help_feed_screen.dart';
import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final String category;
  final String initialNote;

  const HelpRequestDetailScreen({
    super.key,
    required this.category,
    this.initialNote = '',
  });

  @override
  State<HelpRequestDetailScreen> createState() => _HelpRequestDetailScreenState();
}

class _HelpRequestDetailScreenState extends State<HelpRequestDetailScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _rewardController = TextEditingController();

  int _timeSelection = 0; // 0 = Now, 1 = Later
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialNote.isNotEmpty) {
      _descriptionController.text = widget.initialNote;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<String?> _getCurrentAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}";
      }

      return "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitRequest() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    String locationText = _locationController.text.trim();
    double? lat;
    double? lng;

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill title and description.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Auto-fill වත්මන් ස්ථානය + coordinates (field එක හිස් නම්)
    if (locationText.isEmpty) {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          lat = position.latitude;
          lng = position.longitude;

          final autoLocation = await _getCurrentAddress();
          if (autoLocation != null) {
            locationText = autoLocation;
            _locationController.text = autoLocation;
          } else {
            locationText = "${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}";
            _locationController.text = locationText;
          }
        }
      } catch (_) {}
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final created = HelpRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: widget.category,
      title: title,
      description: description,
      locationName: locationText.isEmpty ? 'Nearby' : locationText,
      lat: lat,
      lng: lng,
      isUrgent: _timeSelection == 0,
      isMine: true,
      createdAt: DateTime.now(),
      creatorUid: uid,
    );

    final docId = await HelpRequestService.instance.addRequest(created);
    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (docId == null) {
      HelpRequestsStore.instance.add(created);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally. Sync when online.')),
        );
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Help request posted!',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your request under "${widget.category}" has been shared.',
              ),
              if (locationText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '📍 $locationText',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HelpFeedScreen()),
                  );
                },
                child: const Text('OFFER HELP TO OTHERS', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).popUntil((route) => route.isFirst); // back to HELP feed
              },
              child: const Text('Return to Home', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color redPrimary = Color(0xFFD32F2F);
    const Color redDark = Color(0xFF8B1A1A);

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
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -60,
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
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  title: const Text(
                    'Describe Help',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 19,
                      letterSpacing: -0.3,
                    ),
                  ),
                  centerTitle: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryChip(context, redPrimary),
                        const SizedBox(height: 24),
                        _buildFormCard(
                          context,
                          redPrimary,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(Icons.title_rounded, 'Short title'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _titleController,
                                hint: 'E.g. Need help carrying medical bag',
                                redPrimary: redPrimary,
                              ),
                              const SizedBox(height: 20),
                              _buildLabel(Icons.edit_note_rounded, 'Describe what you need'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _descriptionController,
                                hint: 'Share details like when, where and any special instructions.',
                                redPrimary: redPrimary,
                                minLines: 4,
                                maxLines: 6,
                              ),
                              const SizedBox(height: 20),
                              _buildLabel(Icons.place_rounded, 'Location'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _locationController,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  hintText: 'E.g. Main medical block, 2nd floor',
                                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  prefixIcon: Icon(Icons.location_on_outlined, size: 22, color: redPrimary.withOpacity(0.8)),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: redPrimary, width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildLabel(Icons.schedule_rounded, 'When do you need it?'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildTimeChip('Now', 0, redPrimary),
                                  const SizedBox(width: 12),
                                  _buildTimeChip('Later today', 1, redPrimary),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildLabel(Icons.card_giftcard_rounded, 'Optional thank‑you / reward'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _rewardController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'E.g. 500',
                                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 14, right: 8),
                                    child: Text(
                                      'Rs',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: redPrimary,
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  filled: true,
                                  fillColor: const Color(0xFFFAFAFA),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: redPrimary, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  decoration: BoxDecoration(
                    color: redDark.withOpacity(0.98),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submitRequest,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: redPrimary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(redPrimary),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 22, color: redPrimary),
                                    const SizedBox(width: 10),
                                    Text(
                                      'CONFIRM REQUEST',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.8,
                                        color: redPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, Color redPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [redPrimary, redPrimary.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: redPrimary.withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.handshake_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Help request',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context, Color redPrimary, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color redPrimary,
    int minLines = 1,
    int maxLines = 3,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: redPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, int value, Color redPrimary) {
    final isSelected = _timeSelection == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _timeSelection = value),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? redPrimary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? redPrimary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: redPrimary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

