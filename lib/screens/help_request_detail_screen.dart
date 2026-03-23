import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import '../theme/guardian_ui.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'sos_system/main_menu_screen.dart';

class HelpRequestDetailScreen extends StatefulWidget {
  final String category;
  final String initialNote;

  /// When set, the form opens in edit mode for this request (same Firestore id).
  final HelpRequest? existingRequest;

  const HelpRequestDetailScreen({
    super.key,
    required this.category,
    this.initialNote = '',
    this.existingRequest,
  });

  @override
  State<HelpRequestDetailScreen> createState() =>
      _HelpRequestDetailScreenState();
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

  /// For bottom nav (same role logic as [MainNavigationScreen]).
  String _navUserRole = 'student';

  /// After the first successful submit, further submits update this document.
  String? _persistedDocId;
  DateTime? _createdAtLocked;

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
  static const Map<String, _SlitLocation> _slitBuildings =
      <String, _SlitLocation>{
        'main_gate': _SlitLocation('Main Gate', 6.9149, 79.9736),
        'library': _SlitLocation('Library', 6.9154, 79.9731),
        'auditorium': _SlitLocation('Auditorium', 6.9142, 79.9742),
        'canteen': _SlitLocation('Canteen', 6.9144, 79.9729),
        'car_park': _SlitLocation('Car Park', 6.9152, 79.9730),
        'main_building': _SlitLocation('Main Building', 6.9147, 79.9733),
        'new_building_block': _SlitLocation(
          'New Building/Block',
          6.9150,
          79.9729,
        ),
        'new_building_g_block': _SlitLocation(
          'New Building/G Block',
          6.9151,
          79.9727,
        ),
        'engineering_building': _SlitLocation(
          'Engineering Building',
          6.9153,
          79.9734,
        ),
        'business_school': _SlitLocation('Business School', 6.9150, 79.9732),
        'juice_bar': _SlitLocation('Juice Bar', 6.9149, 79.9731),
        'playground': _SlitLocation('Playground', 6.9147, 79.9730),
        'birdnest': _SlitLocation('Bird Nest', 6.9148, 79.9732),
        'william_angliss': _SlitLocation('William Angliss', 6.9151, 79.9735),
        'other': _SlitLocation('Other', 6.9148, 79.9733),
      };

  // --- Figma-style design tokens (Help request form) ---
  static const double _kFigmaRadius = 12;
  static const Color _kFigmaFieldFill = Color(0xFFF5F5F5);
  static const Color _kFigmaFieldBorder = Color(0xFFE0E0E0);
  /// Primary red from spec (#D32F2F) — focus ring & cursor on inputs.
  static const Color _kFigmaAccent = Color(0xFFD32F2F);
  static const Color _kFigmaInk = Color(0xFF212121);
  static const Color _kFigmaMuted = Color(0xFF757575);
  static const double _kFigmaSectionGap = 16;

  /// After first failed submit, validate as user types (pro UX).
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRequest;
    if (existing != null) {
      _applyExistingRequest(existing);
    } else {
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
      _selectedSlitLocationKey = _slitBuildings.keys.first;
    }

    _loadNavUserRole();
  }

  Future<void> _loadNavUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _navUserRole = 'student');
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _navUserRole = (doc.data()?['role'] ?? 'student').toString();
      });
    } catch (_) {
      if (mounted) setState(() => _navUserRole = 'student');
    }
  }

  Future<void> _onEmbeddedMainNavTap(int index) async {
    final helpIdx = mainNavHelpTabIndexForRole(_navUserRole);
    await handleMainNavBarTap(context, index, (resolved) async {
      if (!mounted) return;
      if (resolved == helpIdx) {
        Navigator.of(context).maybePop();
        return;
      }
      if (resolved != 0) {
        await _loadNavUserRole();
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/navigation',
        (_) => false,
        arguments: resolved,
      );
    });
  }

  String _slitKeyForLocationName(String name) {
    for (final e in _slitBuildings.entries) {
      if (e.value.label == name) {
        return e.key;
      }
    }
    return _slitBuildings.keys.first;
  }

  void _applyExistingRequest(HelpRequest r) {
    _persistedDocId = r.id;
    _createdAtLocked = r.createdAt;
    _requesterNameController.text = r.requesterName;
    _titleController.text = r.title;
    _descriptionController.text = r.description;
    _neededDate = DateTime(r.neededAt.year, r.neededAt.month, r.neededAt.day);
    _neededTime = TimeOfDay(hour: r.neededAt.hour, minute: r.neededAt.minute);
    _selectedSlitLocationKey = _slitKeyForLocationName(r.locationName);

    final p = r.helperPreferences;
    if (p != null) {
      _genderPref = p['genderPreference']?.toString() ?? 'Any';
      _languagePref = p['languagePreference']?.toString() ?? 'Any';
      _verifiedHelpersOnly = p['verifiedHelpersOnly'] == true;
      _vehicleRequirement =
          p['vehicleRequirement']?.toString() ?? 'Not required';
      _preferPreviousRunner = p['preferPreviousRunner'] == true;
      _communicationMode = p['communicationMode']?.toString() ?? 'In-app Chat';
      _tipController.text = p['tipNote']?.toString() ?? '';
      _physicalController.text = p['physicalRequirements']?.toString() ?? '';
    }
  }

  bool get _isUpdateMode => _persistedDocId != null && _createdAtLocked != null;

  String get _effectiveCategory =>
      widget.existingRequest?.category ?? widget.category;

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
            colorScheme: ColorScheme.light(
              primary: redPrimary,
              onPrimary: Colors.white,
            ),
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
            colorScheme: ColorScheme.light(
              primary: redPrimary,
              onPrimary: Colors.white,
            ),
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
      if (mounted) setState(() => _attemptedSubmit = true);
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
        const SnackBar(content: Text('Please select a SLIIT location.')),
      );
      return;
    }

    locationText = building.label;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final requesterName = _requesterNameController.text.trim();
    final neededAt = _combinedNeededAt;

    // Prevent accidentally posting a request for the past.
    if (neededAt.isBefore(
      DateTime.now().subtract(const Duration(minutes: 1)),
    )) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a future date and time for your request.',
          ),
        ),
      );
      return;
    }

    // If the needed time is soon, mark it as urgent. (No extra "Now/Later" fields needed.)
    final isUrgent = neededAt.isBefore(
      DateTime.now().add(const Duration(hours: 2)),
    );

    final category = _effectiveCategory;
    final prefs = _buildHelperPreferencesMap();

    if (_persistedDocId != null && _createdAtLocked != null) {
      final updated = HelpRequest(
        id: _persistedDocId!,
        category: category,
        requesterName: requesterName,
        title: title,
        description: description,
        locationName: locationText.isEmpty ? 'Nearby' : locationText,
        lat: lat,
        lng: lng,
        isUrgent: isUrgent,
        isMine: true,
        createdAt: _createdAtLocked!,
        neededAt: neededAt,
        creatorUid: uid,
        helperPreferences: prefs,
      );

      final ok = await HelpRequestService.instance.updateRequest(
        _persistedDocId!,
        updated,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      if (!mounted) return;

      HelpRequestsStore.instance.upsert(updated);
      if (ok) {
        await HelpRequestService.instance.refreshOnce();
        // Also sync to `alerts` so the "Active Safety Alerts" notification page updates.
        await _upsertEmergencyAlertFromHelpRequest(
          alertId: _persistedDocId!,
          type: category,
          address: locationText.isEmpty ? 'Nearby' : locationText,
          lat: lat,
          lng: lng,
          requesterEmail:
              FirebaseAuth.instance.currentUser?.email ?? requesterName,
        );
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sync update. Saved locally.'),
          ),
        );
      }

      if (mounted) {
        setState(() => _isEditing = true);
      }
      _showPostedDialog(
        isUpdate: true,
        categoryLabel: category,
        locationText: locationText,
      );
      return;
    }

    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    final created = HelpRequest(
      id: localId,
      category: category,
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
      helperPreferences: prefs,
    );

    final docId = await HelpRequestService.instance.addRequest(created);
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _persistedDocId = docId ?? localId;
        _createdAtLocked = created.createdAt;
      });
    }

    if (!mounted) return;

    // Also sync to `alerts` so the "Active Safety Alerts" notification page updates.
    if (docId != null) {
      await _upsertEmergencyAlertFromHelpRequest(
        alertId: docId,
        type: category,
        address: locationText.isEmpty ? 'Nearby' : locationText,
        lat: lat,
        lng: lng,
        requesterEmail:
            FirebaseAuth.instance.currentUser?.email ?? requesterName,
      );
    }

    if (docId == null) {
      HelpRequestsStore.instance.add(created);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally. Sync when online.')),
        );
      }
    } else {
      final saved = HelpRequest(
        id: docId,
        category: created.category,
        requesterName: created.requesterName,
        title: created.title,
        description: created.description,
        locationName: created.locationName,
        lat: created.lat,
        lng: created.lng,
        isUrgent: created.isUrgent,
        isMine: true,
        createdAt: created.createdAt,
        neededAt: created.neededAt,
        creatorUid: created.creatorUid,
        helperPreferences: created.helperPreferences,
      );
      HelpRequestsStore.instance.upsert(saved);
      await HelpRequestService.instance.refreshOnce();
      if (mounted) {
        setState(() {
          _persistedDocId = docId;
        });
      }
    }

    if (mounted) {
      setState(() => _isEditing = true);
    }

    _showPostedDialog(
      isUpdate: false,
      categoryLabel: category,
      locationText: locationText,
    );
  }

  Future<void> _upsertEmergencyAlertFromHelpRequest({
    required String alertId,
    required String type,
    required String address,
    required double? lat,
    required double? lng,
    required String requesterEmail,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('alerts').doc(alertId).set({
        'time': FieldValue.serverTimestamp(),
        'type': type.isNotEmpty ? type : 'HELP REQUEST',
        'address': address,
        'user_email': requesterEmail,
        'lat': lat ?? 0.0,
        'lng': lng ?? 0.0,
        // Optional fields used by tracking screen.
        'user_phone': '',
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('_upsertEmergencyAlertFromHelpRequest failed: $e');
      debugPrint('$st');
    }
  }

  void _showPostedDialog({
    required bool isUpdate,
    required String categoryLabel,
    required String locationText,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isUpdate ? 'Request updated!' : 'Help request posted!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUpdate
                    ? 'Your changes under "$categoryLabel" are saved.'
                    : 'Your request under "$categoryLabel" has been shared.',
              ),
              if (locationText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('📍 $locationText', style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB31217),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text(
                  'View my requests',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isEditing = true);
              },
              child: const Text(
                'Edit again',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final redPrimary = GuardianUi.redPrimary;

    final topBelowAppBar =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 10;

    return Scaffold(
      backgroundColor: GuardianUi.surface,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: MainBottomNavigationBarView(
        currentIndex: mainNavHelpTabIndexForRole(_navUserRole),
        items: buildMainNavBarItems(_navUserRole),
        onTap: (i) => _onEmbeddedMainNavTap(i),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        // Single clear title — subtitle lives in the red header band (no overlap).
        title: Text(
          widget.existingRequest != null ? 'Edit request' : 'Help request',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 17,
            letterSpacing: 0.15,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MainMenuScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft red-tinted page background (organized, on-brand).
          const DecoratedBox(
            decoration: BoxDecoration(gradient: GuardianUi.pageBackgroundWash),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guardian header: gradient + content starts below AppBar (no collision).
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: GuardianUi.headerGradient,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -110,
                        right: -50,
                        child: IgnorePointer(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GuardianUi.orbWarm.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 120,
                        left: -80,
                        child: IgnorePointer(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: GuardianUi.orbCool.withValues(alpha: 0.14),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -50,
                        right: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -30,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          topBelowAppBar,
                          20,
                          22,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              widget.existingRequest != null
                                  ? 'Update details and save when you’re ready.'
                                  : 'Post your request shortly — helpers nearby will see it.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildCategoryChip(context, redPrimary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  child: _buildFormCard(
                    context,
                    redPrimary,
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _attemptedSubmit
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _figmaFormSection(
                            icon: Icons.badge_outlined,
                            label: 'Requester name',
                            child: TextFormField(
                              controller: _requesterNameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              readOnly: !_isEditing,
                              style: _inputTextStyle,
                              cursorColor: _kFigmaAccent,
                              decoration: _inputDecoration(
                                hint:
                                    'Your name as it should appear to helpers',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 22,
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

                                final onlyLettersAndSpaces = RegExp(
                                  r'^[\p{L} ]+$',
                                  unicode: true,
                                );
                                if (!onlyLettersAndSpaces.hasMatch(t)) {
                                  return 'Name should contain letters only';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: _kFigmaSectionGap),
                          _figmaFormSection(
                            icon: Icons.event_rounded,
                            label: 'Date you need help',
                            child: _buildDateTimePickers(
                              context,
                              redPrimary,
                              _isEditing,
                            ),
                          ),
                          const SizedBox(height: _kFigmaSectionGap),
                          _figmaFormSection(
                            icon: Icons.short_text_rounded,
                            label: 'Short title',
                            child: TextFormField(
                              controller: _titleController,
                              textInputAction: TextInputAction.next,
                              readOnly: !_isEditing,
                              style: _inputTextStyle,
                              cursorColor: _kFigmaAccent,
                              decoration: _inputDecoration(
                                hint: 'E.g. Need help carrying medical bag',
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
                          ),
                          const SizedBox(height: _kFigmaSectionGap),
                          _figmaFormSection(
                            icon: Icons.subject_rounded,
                            label: 'Describe what you need',
                            child: TextFormField(
                              controller: _descriptionController,
                              minLines: 2,
                              maxLines: 4,
                              readOnly: !_isEditing,
                              style: _inputTextStyle,
                              cursorColor: _kFigmaAccent,
                              decoration: _inputDecoration(
                                hint:
                                    'Share details like when, where and any special instructions.',
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
                          ),
                          const SizedBox(height: _kFigmaSectionGap),
                          _figmaFormSection(
                            icon: Icons.place_rounded,
                            label: 'Location',
                            child: Column(
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
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: isSel
                                              ? GuardianUi.ctaGradient
                                              : null,
                                          color: isSel
                                              ? null
                                              : _kFigmaFieldFill,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: isSel
                                                ? Colors.transparent
                                                : _kFigmaFieldBorder,
                                            width: isSel ? 0 : 1,
                                          ),
                                          boxShadow: isSel
                                              ? [
                                                  BoxShadow(
                                                    color: GuardianUi.redPrimary
                                                        .withValues(
                                                          alpha: 0.28,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSel)
                                              const Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            if (isSel) const SizedBox(width: 6),
                                            Text(
                                              loc.label,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                                color: isSel
                                                    ? Colors.white
                                                    : _kFigmaInk,
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
                          ),
                          const SizedBox(height: _kFigmaSectionGap),
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
                                child: _buildHelperPreferencesSection(
                                  context,
                                  redPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSubmitting ? null : _submitRequest,
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white, Color(0xFFFFF8F8)],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: GuardianUi.redPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: GuardianUi.redPrimary.withValues(
                                        alpha: 0.22,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            redPrimary,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: GuardianUi.ctaGradient,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: GuardianUi.redPrimary
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ShaderMask(
                                            blendMode: BlendMode.srcIn,
                                            shaderCallback: (bounds) =>
                                                GuardianUi.ctaGradient
                                                    .createShader(bounds),
                                            child: Text(
                                              _isUpdateMode
                                                  ? 'UPDATE REQUEST'
                                                  : 'CONFIRM REQUEST',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                letterSpacing: 0.85,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickers(
    BuildContext context,
    Color redPrimary,
    bool enabled,
  ) {
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
              borderRadius: BorderRadius.circular(_kFigmaRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _kFigmaFieldFill,
                  borderRadius: BorderRadius.circular(_kFigmaRadius),
                  border: Border.all(color: _kFigmaFieldBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: _kFigmaMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kFigmaMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _kFigmaInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: _kFigmaMuted,
                      size: 22,
                    ),
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
              borderRadius: BorderRadius.circular(_kFigmaRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _kFigmaFieldFill,
                  borderRadius: BorderRadius.circular(_kFigmaRadius),
                  border: Border.all(color: _kFigmaFieldBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: _kFigmaMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 11,
                              color: _kFigmaMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _kFigmaInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: _kFigmaMuted,
                      size: 22,
                    ),
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
  Widget _buildHelperPreferencesSection(
    BuildContext context,
    Color redPrimary,
  ) {
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
            GuardianUi.redAccent.withValues(alpha: 0.42),
            GuardianUi.redPrimary.withValues(alpha: 0.32),
            GuardianUi.redDark.withValues(alpha: 0.28),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: GuardianUi.redPrimary.withValues(alpha: 0.16),
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
                    gradient: GuardianUi.ctaGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: GuardianUi.redPrimary.withValues(alpha: 0.32),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
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
                          color: GuardianUi.textPrimary,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: GuardianUi.redPrimary.withValues(alpha: 0.22),
                    ),
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
            _buildPrefSubheading(
              Icons.wc_rounded,
              'Helper gender preference',
              redPrimary,
            ),
            const SizedBox(height: 10),
            _buildOptionChips(
              options: const ['Male', 'Female', 'Any'],
              selected: _genderPref,
              redPrimary: redPrimary,
              onSelected: (v) => setState(() => _genderPref = v),
              enabled: _isEditing,
            ),
            const SizedBox(height: 20),
            _buildPrefSubheading(
              Icons.language_rounded,
              'Language preference',
              redPrimary,
            ),
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
            _buildPrefSubheading(
              Icons.pedal_bike_rounded,
              'Vehicle requirement',
              redPrimary,
            ),
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
            _buildPrefSubheading(
              Icons.forum_rounded,
              'Preferred communication',
              redPrimary,
            ),
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
            const SizedBox(height: 10),
            TextFormField(
              controller: _tipController,
              textInputAction: TextInputAction.next,
              readOnly: !_isEditing,
              style: _inputTextStyle,
              cursorColor: _kFigmaAccent,
              decoration: _inputDecoration(
                hint: 'E.g. LKR 100 — motivates helpers (optional)',
              ),
              validator: _validateTip,
            ),
            const SizedBox(height: 18),
            _buildLabel(
              Icons.accessible_forward_rounded,
              'Physical / special requirements',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _physicalController,
              minLines: 2,
              maxLines: 3,
              readOnly: !_isEditing,
              style: _inputTextStyle,
              cursorColor: _kFigmaAccent,
              decoration: _inputDecoration(
                hint:
                    'E.g. Must lift heavy items, comfortable with wheelchair…',
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
        Icon(icon, size: 17, color: redPrimary.withValues(alpha: 0.9)),
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
                gradient: isSel ? GuardianUi.ctaGradient : null,
                color: isSel ? null : GuardianUi.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSel ? Colors.transparent : GuardianUi.divider,
                  width: 1.2,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: GuardianUi.redPrimary.withValues(alpha: 0.32),
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
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: GuardianUi.headerCardShadow,
        border: Border.all(color: GuardianUi.divider.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: GuardianUi.ctaGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: GuardianUi.redPrimary.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.handshake_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _effectiveCategory,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    Color redPrimary, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: GuardianUi.divider.withValues(alpha: 0.85)),
        boxShadow: GuardianUi.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildLabel(IconData icon, String text, {bool required = false}) {
    const labelStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      letterSpacing: 0.08,
      height: 1.2,
      color: _kFigmaInk,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kFigmaFieldFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kFigmaFieldBorder),
          ),
          child: Icon(icon, size: 20, color: _kFigmaMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: text, style: labelStyle),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: _kFigmaAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Figma block: icon tile + label row, 8px, then control(s).
  Widget _figmaFormSection({
    required IconData icon,
    required String label,
    required Widget child,
    bool requiredMark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabel(icon, label, required: requiredMark),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: _kFigmaInk,
        letterSpacing: 0.02,
      );

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
  }) {
    final r = BorderRadius.circular(_kFigmaRadius);
    const errorColor = Color(0xFFC62828);
    final prefix = prefixIcon == null
        ? null
        : IconTheme.merge(
            data: const IconThemeData(
              size: 21,
              color: _kFigmaMuted,
            ),
            child: prefixIcon,
          );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _kFigmaMuted.withValues(alpha: 0.88),
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      filled: true,
      fillColor: _kFigmaFieldFill,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      errorStyle: const TextStyle(
        color: errorColor,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      errorMaxLines: 2,
      border: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: _kFigmaFieldBorder, width: 1),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: _kFigmaFieldBorder.withValues(alpha: 0.7)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: errorColor, width: 1.25),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: _kFigmaFieldBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: _kFigmaAccent, width: 1.25),
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
