import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'help_feed_screen.dart';
import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import 'profile_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _requesterNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _tipController = TextEditingController();
  final _physicalController = TextEditingController();

  bool _isSubmitting = false;
  // Keep the form editable by default. We only need the "Edit request"
  // flow after submission (dialog button).
  bool _isEditing = true;

  DateTime _neededDate = DateTime.now();
  TimeOfDay _neededTime = TimeOfDay.now();

  String _genderPref = 'Any';
  String _languagePref = 'Any';
  bool _verifiedHelpersOnly = false;
  String _vehicleRequirement = 'Not required';
  bool _preferPreviousRunner = false;
  String _communicationMode = 'In-app Chat';

  /// Location picker for SLIIT-only requests (uses building coordinates,
  /// while the user enters the lab code from the provided floor/lab map).
  String? _selectedSlitLocationKey;

  // Building/location categories shown in the form.
  // Coordinates are approximate inside the SLIIT Malabe campus so Google Maps can open correctly.
  static const Map<String, _SlitLocation> _slitBuildings = <String, _SlitLocation>{
    'main_gate': _SlitLocation('Main Gate', 6.9149, 79.9736),
    'library': _SlitLocation('Library', 6.9154, 79.9731),
    'auditorium': _SlitLocation('Auditorium', 6.9142, 79.9742),
    'canteen': _SlitLocation('Canteen', 6.9144, 79.9729),
    'car_park': _SlitLocation('Car Park', 6.9152, 79.9730),
    'main_building': _SlitLocation('Main Building', 6.9147, 79.9733),
    'new_building_block': _SlitLocation('New Building/Block', 6.9150, 79.9729),
    'new_building_g_block': _SlitLocation('New Building/G Block', 6.9151, 79.9727),
    'engineering_building': _SlitLocation('Engineering Building', 6.9153, 79.9734),
    'business_school': _SlitLocation('Business School', 6.9150, 79.9732),
    'juice_bar': _SlitLocation('Juice Bar', 6.9149, 79.9731),
    'playground': _SlitLocation('Playground', 6.9147, 79.9730),
    'birdnest': _SlitLocation('Bird Nest', 6.9148, 79.9732),
    'william_angliss': _SlitLocation('William Angliss', 6.9151, 79.9735),
    'other': _SlitLocation('Other', 6.9148, 79.9733),
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final dn = user?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      _requesterNameController.text = dn;
    }
    if (widget.initialNote.isNotEmpty) {
      _descriptionController.text = widget.initialNote;
    }
    final now = DateTime.now();
    _neededDate = DateTime(now.year, now.month, now.day);
    _neededTime = TimeOfDay.fromDateTime(now);

    // Default to a valid SLIIT building so coordinates are always available.
    _selectedSlitLocationKey = _slitBuildings.keys.first;
  }

  @override
  void dispose() {
    _requesterNameController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tipController.dispose();
    _physicalController.dispose();
    super.dispose();
  }

  DateTime get _combinedNeededAt => DateTime(
        _neededDate.year,
        _neededDate.month,
        _neededDate.day,
        _neededTime.hour,
        _neededTime.minute,
      );

  Future<void> _pickNeededDate(Color redPrimary) async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededDate.isBefore(first) ? first : _neededDate,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: redPrimary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _neededDate = picked);
  }

  Future<void> _pickNeededTime(Color redPrimary) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _neededTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(primary: redPrimary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _neededTime = picked);
  }

  String? _validateTip(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length > 80) return 'Keep tip text under 80 characters';
    final digits = RegExp(r'\d+').firstMatch(t.replaceAll(',', ''));
    if (digits == null) return 'Include an amount (e.g. LKR 100)';
    final n = int.tryParse(digits.group(0)!);
    if (n == null || n <= 0) return 'Enter a valid positive amount';
    return null;
  }

  String? _validatePhysical(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (t.length < 5) return 'Add a bit more detail (at least 5 characters)';
    if (t.length > 500) return 'Maximum 500 characters';
    return null;
  }

  Map<String, dynamic> _buildHelperPreferencesMap() {
    final tip = _tipController.text.trim();
    final phys = _physicalController.text.trim();
    return <String, dynamic>{
      'genderPreference': _genderPref,
      'languagePreference': _languagePref,
      'verifiedHelpersOnly': _verifiedHelpersOnly,
      'vehicleRequirement': _vehicleRequirement,
      'preferPreviousRunner': _preferPreviousRunner,
      'communicationMode': _communicationMode,
      if (tip.isNotEmpty) 'tipNote': tip,
      if (phys.isNotEmpty) 'physicalRequirements': phys,
    };
  }

  Future<void> _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final buildingKey = _selectedSlitLocationKey;
    final building = buildingKey == null ? null : _slitBuildings[buildingKey];

    String locationText = '';
    double? lat = building?.lat;
    double? lng = building?.lng;

    setState(() {
      _isSubmitting = true;
    });

    if (building == null) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a SLIIT location.',
          ),
        ),
      );
      return;
    }

    locationText = building.label;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final requesterName = _requesterNameController.text.trim();
    final neededAt = _combinedNeededAt;

    // Prevent accidentally posting a request for the past.
    if (neededAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future date and time for your request.')),
      );
      return;
    }

    // If the needed time is soon, mark it as urgent. (No extra "Now/Later" fields needed.)
    final isUrgent = neededAt.isBefore(DateTime.now().add(const Duration(hours: 2)));

    final created = HelpRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: widget.category,
      requesterName: requesterName,
      title: title,
      description: description,
      locationName: locationText.isEmpty ? 'Nearby' : locationText,
      lat: lat,
      lng: lng,
      isUrgent: isUrgent,
      isMine: true,
      createdAt: DateTime.now(),
      neededAt: neededAt,
      creatorUid: uid,
      helperPreferences: _buildHelperPreferencesMap(),
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

    // After posting, keep the user in the same form and allow corrections.
    if (mounted) {
      setState(() {
        _isEditing = true;
      });
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
                // Allow the user to correct fields on the same form.
                setState(() => _isEditing = true);
              },
              child: const Text('Edit request', style: TextStyle(color: Colors.grey)),
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
                    'Post your request shortly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      tooltip: 'Profile',
                      icon: const Icon(Icons.person_rounded),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    // Make room for the fixed bottom confirm button
                    // so validation error texts won't be hidden.
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryChip(context, redPrimary),
                        const SizedBox(height: 24),
                        _buildFormCard(
                          context,
                          redPrimary,
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(Icons.badge_outlined, 'Requester name'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _requesterNameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  readOnly: !_isEditing,
                                  decoration: _inputDecoration(
                                    hint: 'Your name as it should appear to helpers',
                                    redPrimary: redPrimary,
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      size: 22,
                                      color: redPrimary.withOpacity(0.8),
                                    ),
                                  ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    if (t.length < 2) {
                                      return 'Name must be at least 2 characters';
                                    }
                                    if (t.length > 80) {
                                      return 'Name is too long';
                                    }
                                    // Letters + spaces only (supports Sinhala/Tamil/etc via Unicode categories).
                                    final onlyLettersAndSpaces = RegExp(r'^[\p{L} ]+$', unicode: true);
                                    if (!onlyLettersAndSpaces.hasMatch(t)) {
                                      return 'Name should contain letters only';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLabel(Icons.event_rounded, 'Date you need help'),
                                const SizedBox(height: 8),
                                _buildDateTimePickers(context, redPrimary, _isEditing),
                                const SizedBox(height: 20),
                                _buildLabel(Icons.title_rounded, 'Short title'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleController,
                                  textInputAction: TextInputAction.next,
                                  readOnly: !_isEditing,
                                  decoration: _inputDecoration(
                                    hint: 'E.g. Need help carrying medical bag',
                                    redPrimary: redPrimary,
                                  ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) {
                                      return 'Please enter a short title';
                                    }
                                    if (t.length < 2) {
                                      return 'Title must be at least 2 characters';
                                    }
                                    if (t.length > 80) {
                                      return 'Title is too long';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLabel(Icons.edit_note_rounded, 'Describe what you need'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  minLines: 2,
                                  maxLines: 4,
                                  readOnly: !_isEditing,
                                  decoration: _inputDecoration(
                                    hint: 'Share details like when, where and any special instructions.',
                                    redPrimary: redPrimary,
                                  ),
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) {
                                      return 'Please describe what you need';
                                    }
                                    if (t.length < 5) {
                                      return 'Please add a bit more detail (at least 5 characters)';
                                    }
                                    if (t.length > 400) {
                                      return 'Description is too long (max 400 characters)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLabel(Icons.place_rounded, 'Location'),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _slitBuildings.entries.map((entry) {
                                        final key = entry.key;
                                        final loc = entry.value;
                                        final isSel = _selectedSlitLocationKey == key;
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _isEditing
                                                ? () {
                                                    setState(() {
                                                      _selectedSlitLocationKey = key;
                                                    });
                                                  }
                                                : null,
                                            borderRadius: BorderRadius.circular(24),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 180),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSel ? redPrimary : Colors.white,
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: isSel
                                                      ? redPrimary
                                                      : Colors.grey.shade300,
                                                  width: isSel ? 2 : 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isSel)
                                                    const Icon(Icons.check_rounded,
                                                        size: 18, color: Colors.white),
                                                  if (isSel) const SizedBox(width: 6),
                                                  Text(
                                                    loc.label,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                      color: isSel
                                                          ? Colors.white
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ExpansionTile(
                                  enabled: _isEditing,
                                  tilePadding: EdgeInsets.zero,
                                  collapsedIconColor: redPrimary,
                                  iconColor: redPrimary,
                                  backgroundColor: Colors.transparent,
                                  collapsedBackgroundColor: Colors.transparent,
                                  childrenPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Advanced options (optional)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: redPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.expand_more_rounded),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _buildHelperPreferencesSection(context, redPrimary),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ],
                            ),
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

  Widget _buildDateTimePickers(BuildContext context, Color redPrimary, bool enabled) {
    final dateStr = DateFormat.yMMMEd().format(_neededDate);
    final timeStr = _neededTime.format(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => _pickNeededDate(redPrimary) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20, color: redPrimary.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: Colors.grey.shade500, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? () => _pickNeededTime(redPrimary) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: redPrimary.withOpacity(0.85)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: Colors.grey.shade500, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Optional helper-matching preferences — chips, toggles, dropdown, with validations on tip & physical notes.
  Widget _buildHelperPreferencesSection(BuildContext context, Color redPrimary) {
    const cream = Color(0xFFFFF8F8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            redPrimary.withOpacity(0.55),
            redPrimary.withOpacity(0.2),
            const Color(0xFF6B1515).withOpacity(0.35),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: redPrimary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [redPrimary, redPrimary.withOpacity(0.75)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: redPrimary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Helper preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Fine-tune who can respond — all optional.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: redPrimary.withOpacity(0.25)),
                  ),
                  child: Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: redPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildPrefSubheading(Icons.wc_rounded, 'Helper gender preference', redPrimary),
            const SizedBox(height: 10),
            _buildOptionChips(
              options: const ['Male', 'Female', 'Any'],
              selected: _genderPref,
              redPrimary: redPrimary,
              onSelected: (v) => setState(() => _genderPref = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            _buildPrefSubheading(Icons.language_rounded, 'Language preference', redPrimary),
            const SizedBox(height: 10),
            _buildOptionChips(
              options: const ['English', 'Sinhala', 'Tamil', 'Any'],
              selected: _languagePref,
              redPrimary: redPrimary,
              onSelected: (v) => setState(() => _languagePref = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 18),
            _buildPremiumSwitchTile(
              title: 'Request verified helpers only',
              subtitle: 'Background-verified or highly rated runners only.',
              value: _verifiedHelpersOnly,
              redPrimary: redPrimary,
              onChanged: (v) => setState(() => _verifiedHelpersOnly = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildPrefSubheading(Icons.pedal_bike_rounded, 'Vehicle requirement', redPrimary),
            const SizedBox(height: 10),
            _buildOptionChips(
              options: const ['Not required', 'Bike', 'Car'],
              selected: _vehicleRequirement,
              redPrimary: redPrimary,
              onSelected: (v) => setState(() => _vehicleRequirement = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildPremiumSwitchTile(
              title: 'Prefer my previous runner',
              subtitle: 'We’ll try to notify someone who helped you before.',
              value: _preferPreviousRunner,
              redPrimary: redPrimary,
              onChanged: (v) => setState(() => _preferPreviousRunner = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            _buildPrefSubheading(Icons.forum_rounded, 'Preferred communication', redPrimary),
            const SizedBox(height: 10),
            _buildOptionChips(
              options: const ['Phone Call', 'In-app Chat', 'SMS'],
              selected: _communicationMode,
              redPrimary: redPrimary,
              onSelected: (v) => setState(() => _communicationMode = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            _buildLabel(Icons.card_giftcard_rounded, 'Estimated tip / reward'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tipController,
              textInputAction: TextInputAction.next,
              readOnly: !_isEditing,
              decoration: _inputDecoration(
                hint: 'E.g. LKR 100 — motivates helpers (optional)',
                redPrimary: redPrimary,
              ),
              validator: _validateTip,
            ),
            const SizedBox(height: 18),
            _buildLabel(Icons.accessible_forward_rounded, 'Physical / special requirements'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _physicalController,
              minLines: 2,
              maxLines: 3,
              readOnly: !_isEditing,
              decoration: _inputDecoration(
                hint: 'E.g. Must lift heavy items, comfortable with wheelchair…',
                redPrimary: redPrimary,
              ),
              validator: _validatePhysical,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefSubheading(IconData icon, String text, Color redPrimary) {
    return Row(
      children: [
        Icon(icon, size: 17, color: redPrimary.withOpacity(0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Colors.grey.shade800,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChips({
    required List<String> options,
    required String selected,
    required Color redPrimary,
    required ValueChanged<String> onSelected,
    bool enabled = true,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((label) {
        final isSel = selected == label;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => onSelected(label) : null,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSel
                    ? LinearGradient(
                        colors: [redPrimary, redPrimary.withOpacity(0.82)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSel ? null : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSel ? Colors.transparent : Colors.grey.shade300,
                  width: 1.2,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: redPrimary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSel) ...[
                    const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isSel ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Color redPrimary,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: redPrimary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: enabled ? onChanged : null,
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

  Widget _buildLabel(IconData icon, String text, {bool required = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black87),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: text,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color redPrimary,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Make validation text visible and consistent with the red theme.
      errorStyle: TextStyle(
        color: redPrimary,
        fontSize: 12,
        height: 1.2,
      ),
      errorMaxLines: 2,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: redPrimary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: redPrimary, width: 2),
      ),
    );
  }

  // Note: Earlier versions had Now/Later chips; the current UI uses Date+Time pickers instead.
}

class _SlitLocation {
  final String label;
  final double lat;
  final double lng;

  const _SlitLocation(this.label, this.lat, this.lng);
}

