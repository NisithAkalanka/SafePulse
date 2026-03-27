import 'dart:ui';
<<<<<<< Updated upstream
=======
import 'dart:io';
import 'dart:convert';
>>>>>>> Stashed changes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'mock_chat_screen.dart';

const Color lfRed = Color(0xFFE53935);
const Color lfBg = Color(0xFFF6F6F7);
const Color lfTextPrimary = Color(0xFF1E1E1E);
const Color lfTextSecondary = Color(0xFF4B4B4B);
const Color lfTextMuted = Color(0xFF707070);

class LostFoundDetailScreen extends StatefulWidget {
  final LostItem item;

  const LostFoundDetailScreen({super.key, required this.item});

  @override
  State<LostFoundDetailScreen> createState() => _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends State<LostFoundDetailScreen> {
  final ImagePicker _picker = ImagePicker();

  bool get isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == widget.item.userId;
  }

  bool get isRequester {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == widget.item.requesterId;
  }

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  String get currentName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  bool get isActiveStatus => widget.item.status == 'Active';

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageBg => isDark ? const Color(0xFF121217) : lfBg;
  Color get cardBg => isDark ? const Color(0xFF1B1B22) : Colors.white;
  Color get softBg =>
      isDark ? const Color(0xFF23232B) : const Color(0xFFF3F3F3);
  Color get textPrimary => isDark ? Colors.white : lfTextPrimary;
  Color get textSecondary => isDark ? const Color(0xFFB7BBC6) : lfTextSecondary;
  Color get textMuted => isDark ? const Color(0xFF9EA4B0) : lfTextMuted;
  Color get borderColor =>
      isDark ? const Color(0xFF34343F) : const Color(0xFFE5E7EE);

  Color get editYellowLight1 => const Color(0xFFE7D79A);
  Color get editYellowLight2 => const Color(0xFFCDB46E);
  Color get editYellowDark1 => const Color(0xFFE3CF8A);
  Color get editYellowDark2 => const Color(0xFFB79E57);

  Color get editButtonColor1 => isDark ? editYellowDark1 : editYellowLight1;
  Color get editButtonColor2 => isDark ? editYellowDark2 : editYellowLight2;
  Color get editGlowColor => isDark
      ? const Color(0xFFB79E57).withOpacity(0.28)
      : const Color(0xFFCDB46E).withOpacity(0.24);

  static const List<String> _editCategories = <String>[
    'Electronics',
    'ID/Documents',
    'Student ID Card',
    'Watch',
    'Keys',
    'Books',
    'Others',
  ];

  static const List<String> _editLocations = <String>[
    'Main Gate',
    'Library',
    'Auditorium',
    'Canteen',
    'Car Park',
    'Main Building',
    'New Building/Block',
    'New Building/G Block',
    'Engineering Building',
    'Business School',
    'Juice Bar',
    'Playground',
    'Bird Nest',
    'William Angliss',
    'Other',
  ];

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: lfRed, width: 2.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: lfRed.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dialogFieldDecoration(String hint, {String? label}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(color: textMuted),
      labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: isDark ? const Color(0xFF24242C) : const Color(0xFFF7F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lfRed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  String? _validateQuestion(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Question is required';
    if (v.length < 5) return 'Question must be at least 5 characters';
    if (v.length > 120) return 'Question must be 120 characters or less';
    final RegExp reg = RegExp(r"^[a-zA-Z0-9\s&(),.\-'/?!]+$");
    if (!reg.hasMatch(v)) return 'Question contains invalid characters';
    return null;
  }

  String? _validateAnswer(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Answer is required';
    if (v.length < 2) return 'Answer must be at least 2 characters';
    if (v.length > 150) return 'Answer must be 150 characters or less';
    return null;
  }

  String? _validateProof(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Proof is required';
    if (v.length < 3) return 'Proof must be at least 3 characters';
    if (v.length > 150) return 'Proof must be 150 characters or less';
    return null;
  }

  String? _requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateAlphaNumericRequired(String? value, String label) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';

    final RegExp reg = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!reg.hasMatch(v)) {
      return '$label can contain only letters and numbers';
    }
    return null;
  }

  String _formatPostedDate(DateTime date) {
    const List<String> months = <String>[
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatPostedTime(DateTime date) {
    final int hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _posterDisplayName(LostItem item) {
    final String first = (item.firstName ?? '').trim();
    final String last = (item.lastName ?? '').trim();
    final String full = '$first $last'.trim();

    if (full.isNotEmpty) return full;
    if (item.userName.trim().isNotEmpty) return item.userName.trim();
    return 'Anonymous';
  }

<<<<<<< Updated upstream
=======
  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 40, color: lfRed),
      );
    }

    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 40, color: lfRed),
          );
        },
      );
    } catch (_) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, size: 40, color: lfRed),
      );
    }
  }

  Future<File?> _pickEditedImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (image == null) return null;
    return File(image.path);
  }

  Widget _buildEditLocationChip({
    required String location,
    required String selectedLocation,
    required StateSetter setLocalState,
    required TextEditingController otherLocationController,
  }) {
    final bool isSelected = selectedLocation == location;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            setLocalState(() {
              if (location != 'Other') {
                otherLocationController.clear();
              }
            });
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF4B4B), Color(0xFFD81B1B)],
                    )
                  : null,
              color: isSelected
                  ? null
                  : (isDark
                        ? const Color(0xFF24242C)
                        : const Color(0xFFF7F7F8)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF5A5A)
                    : (isDark
                          ? const Color(0xFF34343F)
                          : const Color(0xFFD4D4D8)),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: lfRed.withOpacity(0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              location,
              style: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

>>>>>>> Stashed changes
  Future<void> _showEditDialog() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController titleController = TextEditingController(
      text: widget.item.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: widget.item.description,
    );
    final TextEditingController otherLocationController =
        TextEditingController();

    String selectedCategory = _editCategories.contains(widget.item.category)
        ? widget.item.category
        : _editCategories.first;

    String selectedLocation = _editLocations.contains(widget.item.location)
        ? widget.item.location
        : 'Other';

    if (selectedLocation == 'Other') {
      otherLocationController.text = widget.item.location;
    }

    DateTime selectedDate =
        widget.item.reportedDateTime ?? widget.item.timestamp;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      widget.item.reportedDateTime ?? widget.item.timestamp,
    );

    File? selectedImageFile;
    bool removePhoto = false;

    Future<void> pickDate(StateSetter setLocalState) async {
      final now = DateTime.now();

      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate.isAfter(now) ? now : selectedDate,
        firstDate: DateTime(2024),
        lastDate: now,
      );

      if (picked != null) {
        setLocalState(() {
          selectedDate = picked;
          final pickedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          if (pickedDateTime.isAfter(now)) {
            selectedTime = TimeOfDay.fromDateTime(now);
          }
        });
      }
    }

    Future<void> pickTime(StateSetter setLocalState) async {
      final now = DateTime.now();

      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        initialEntryMode: TimePickerEntryMode.input,
      );

      if (picked != null) {
        final selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          picked.hour,
          picked.minute,
        );

        if (selectedDateTime.isAfter(now)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Future time cannot be selected')),
          );
          return;
        }

        setLocalState(() {
          selectedTime = picked;
        });
      }
    }

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Edit item',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.20),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StatefulBuilder(
                    builder: (context, setLocalState) {
                      final bool isOtherLocationSelected =
                          selectedLocation == 'Other';

                      final String finalLocation = isOtherLocationSelected
                          ? otherLocationController.text.trim()
                          : selectedLocation;

                      Widget imagePreview() {
                        if (selectedImageFile != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              selectedImageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          );
                        }

                        if (removePhoto) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported_outlined,
                                size: 42,
                                color: lfRed,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No photo selected',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                        }

                        if (widget.item.imageData != null &&
                            widget.item.imageData!.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _buildImage(widget.item.imageData),
                          );
                        }

                        if (widget.item.imageUrl.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              widget.item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (c, e, s) {
                                return const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 40,
                                    color: lfRed,
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_outlined,
                              size: 42,
                              color: lfRed,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload photo',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      }

                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 430),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: editGlowColor.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: <Color>[
                                              editButtonColor1,
                                              editButtonColor2,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Edit item',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Update the item details below.',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  GestureDetector(
                                    onTap: () async {
                                      final file = await _pickEditedImage();
                                      if (file != null) {
                                        setLocalState(() {
                                          selectedImageFile = file;
                                          removePhoto = false;
                                        });
                                      }
                                    },
                                    child: Container(
                                      height: 180,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: softBg,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: imagePreview(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final file =
                                                await _pickEditedImage();
                                            if (file != null) {
                                              setLocalState(() {
                                                selectedImageFile = file;
                                                removePhoto = false;
                                              });
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.photo_library_outlined,
                                          ),
                                          label: const Text('Change Photo'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: lfRed,
                                            side: BorderSide(
                                              color: borderColor,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setLocalState(() {
                                              selectedImageFile = null;
                                              removePhoto = true;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: const Text('Remove Photo'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                            side: BorderSide(
                                              color: borderColor,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: titleController,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9\s]'),
                                      ),
                                    ],
                                    validator: (v) =>
                                        _validateAlphaNumericRequired(
                                          v,
                                          'Title',
                                        ),
                                    decoration: _dialogFieldDecoration(
                                      'Title',
                                      label: 'Title',
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  DropdownButtonFormField<String>(
                                    dropdownColor: cardBg,
                                    value: selectedCategory,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: textSecondary,
                                    ),
                                    decoration: _dialogFieldDecoration(
                                      '',
                                      label: 'Category',
                                    ),
                                    items: _editCategories
                                        .map(
                                          (String c) =>
                                              DropdownMenuItem<String>(
                                                value: c,
                                                child: Text(c),
                                              ),
                                        )
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setLocalState(() {
                                          selectedCategory = value;
                                        });
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () => pickDate(setLocalState),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF24242C)
                                                  : const Color(0xFFF7F7F8),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Date',
                                                  style: TextStyle(
                                                    color: textMuted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatPostedDate(
                                                    selectedDate,
                                                  ),
                                                  style: TextStyle(
                                                    color: textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () => pickTime(setLocalState),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF24242C)
                                                  : const Color(0xFFF7F7F8),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: borderColor,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Time',
                                                  style: TextStyle(
                                                    color: textMuted,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  selectedTime.format(context),
                                                  style: TextStyle(
                                                    color: textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF24242C)
                                          : const Color(0xFFF7F7F8),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _editLocations
                                              .map(
                                                (
                                                  location,
                                                ) => _buildEditLocationChip(
                                                  location: location,
                                                  selectedLocation:
                                                      selectedLocation,
                                                  setLocalState: (innerSetState) {
                                                    setLocalState(() {
                                                      selectedLocation =
                                                          location;
                                                      if (location != 'Other') {
                                                        otherLocationController
                                                            .clear();
                                                      }
                                                    });
                                                  },
                                                  otherLocationController:
                                                      otherLocationController,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        if (isOtherLocationSelected) ...[
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: otherLocationController,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[a-zA-Z0-9\s]'),
                                              ),
                                            ],
                                            validator: (v) =>
                                                _validateAlphaNumericRequired(
                                                  v,
                                                  'Other location',
                                                ),
                                            decoration: _dialogFieldDecoration(
                                              'Type other location',
                                              label: 'Other location',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  TextFormField(
                                    controller: descriptionController,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 4,
                                    maxLength: 300,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9\s]'),
                                      ),
                                    ],
                                    validator: (v) =>
                                        _validateAlphaNumericRequired(
                                          v,
                                          'Description',
                                        ),
                                    decoration: _dialogFieldDecoration(
                                      'Description',
                                      label: 'Description',
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                editButtonColor1,
                                                editButtonColor2,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: editGlowColor,
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              if (!formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }

                                              final DateTime reportDateTime =
                                                  _combineDateAndTime(
                                                    selectedDate,
                                                    selectedTime,
                                                  );

                                              if (reportDateTime.isAfter(
                                                DateTime.now(),
                                              )) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Future date and time cannot be selected',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              if (finalLocation.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Location is required',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }

                                              await LostFoundService()
                                                  .updatePostFull(
                                                    itemId: widget.item.id,
                                                    title: titleController.text
                                                        .trim(),
                                                    category: selectedCategory,
                                                    description:
                                                        descriptionController
                                                            .text
                                                            .trim(),
                                                    location: finalLocation,
                                                    reportedDateTime:
                                                        reportDateTime,
                                                    imageFile:
                                                        selectedImageFile,
                                                    removePhoto: removePhoto,
                                                  );

                                              if (!mounted) return;
                                              Navigator.pop(context);
                                              Navigator.pop(context);

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Item updated successfully.',
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            child: const Text(
                                              'Save',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
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
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final bool? shouldDelete = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Delete',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: lfRed, width: 2),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.delete_outline,
                          size: 42,
                          color: lfRed,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Delete item',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'are you sure you want to delete?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lfRed,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    await LostFoundService().deletePost(widget.item.id);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item deleted successfully.')));
  }

  Future<void> _showFoundQuestionDialog() async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Ask verification question',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
              validator: _validateQuestion,
              decoration: _dialogFieldDecoration(
                'e.g. Any special marks on the item?',
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().submitFoundReport(
                  itemId: widget.item.id,
                  requesterId: currentUid,
                  requesterName: currentName,
                  question: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Found report sent.')),
                );
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOwnerAnswerDialog() async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final String question = await LostFoundService().getVerificationQuestion(
      widget.item.id,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Answer verification question',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  question,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: _validateAnswer,
                  decoration: _dialogFieldDecoration('Type your answer'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().submitOwnerAnswer(
                  itemId: widget.item.id,
                  answer: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Answer sent to finder.')),
                );
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClaimDialog() async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Verification Required',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Describe any special marks or unique details.',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: _validateProof,
                  decoration: _dialogFieldDecoration('Type proof here'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().submitClaimRequest(
                  itemId: widget.item.id,
                  requesterId: currentUid,
                  requesterName: currentName,
                  proofAnswer: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Claim request sent.')),
                );
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockChatScreen(
          itemId: widget.item.id,
          otherUserName: widget.item.requesterName ?? widget.item.userName,
          itemName: widget.item.title,
        ),
      ),
    );
  }

  String _detailDeleteTime() {
    final DateTime? returnedAt = widget.item.returnedAt;
    if (returnedAt == null) return 'Deletes in 1h 0m';

    final DateTime expiry = returnedAt.add(const Duration(hours: 1));
    final Duration remaining = expiry.difference(DateTime.now());

    if (remaining.isNegative) return 'Deleting soon';

    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Deletes in ${hours}h ${minutes}m';
    }
    return 'Deletes in ${minutes}m';
  }

  Widget _buildHeader() {
    final bool isLost = widget.item.type == 'Lost';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 100, 18, 18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFF3B3B),
                  Color(0xFFE10613),
                  Color(0xFFB30012),
                  Color(0xFF140910),
                ],
                stops: <double>[0.0, 0.35, 0.72, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: <double>[0.0, 0.62, 1.0],
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Text(
        isLost
            ? 'Review the lost item details carefully.'
            : 'Review the found item details carefully.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    Color bg;
    Color fg;

    switch (widget.item.status) {
      case 'Returned':
        bg = const Color(0xFFE8F6EA);
        fg = const Color(0xFF2E7D32);
        break;
      case 'Claim Pending':
      case 'Verification Pending':
        bg = const Color(0xFFFFF4DB);
        fg = const Color(0xFFB26A00);
        break;
      case 'Chat Enabled':
      case 'Answer Submitted':
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF1565C0);
        break;
      default:
        bg = lfRed.withOpacity(0.08);
        fg = lfRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.item.status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _ownerActionButtons() {
    if (!isOwner || !isActiveStatus) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[editButtonColor1, editButtonColor2],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: editGlowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showEditDialog,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.edit_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: lfRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: lfRed.withOpacity(0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsTopCard() {
    final LostItem item = widget.item;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: lfRed,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 42,
                      color: lfRed,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lfRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You posted',
                    style: TextStyle(
                      color: lfRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.place_outlined, size: 18, color: textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.location,
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Posted: ${_formatPostedDate(item.timestamp)}',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Time: ${_formatPostedTime(item.timestamp)}',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (item.reportedDateTime != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reported item date: ${_formatPostedDate(item.reportedDateTime!)} ${_formatPostedTime(item.reportedDateTime!)}',
              style: TextStyle(
                color: textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                'Status:',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              _statusBadge(),
            ],
          ),
          if (item.status == 'Returned') ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _detailDeleteTime(),
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailSection(String title, String value, IconData icon) {
    return _panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: lfRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: lfRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _ownerLostVerificationCard() {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationQuestion(widget.item.id),
        builder: (context, snap) {
          final String question = snap.data ?? 'Loading question...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Finder verification request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _primaryButton('ANSWER QUESTION', _showOwnerAnswerDialog),
            ],
          );
        },
      ),
    );
  }

  Widget _finderApprovalCard() {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(widget.item.id),
        builder: (context, snap) {
          final String answer = snap.data ?? 'Loading answer...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Owner's verification answer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await LostFoundService().rejectRequest(widget.item.id);
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(
                          widget.item.id,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lfRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _requesterWaitingCard(String text) {
    return _panel(
      child: Row(
        children: <Widget>[
          const Icon(Icons.hourglass_top_rounded, color: lfRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Private chat enabled',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can now coordinate the item return safely.',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          _primaryButton('OPEN CHAT', _openChat),
        ],
      ),
    );
  }

  List<Widget> _buildWorkflowCards() {
    final LostItem item = widget.item;
    final List<Widget> cards = <Widget>[];

    if (item.chatEnabled == true) {
      cards.add(_chatCard());
      return cards;
    }

    if (item.type == 'Lost') {
      if (!isOwner && item.status == 'Active') {
        cards.add(
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Claim this item',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provide proof to request ownership verification.',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _primaryButton('I FOUND THIS', _showClaimDialog),
              ],
            ),
          ),
        );
      } else if (isOwner && item.status == 'Claim Pending') {
        cards.add(_ownerLostVerificationCard());
      } else if (!isOwner &&
          isRequester &&
          (item.status == 'Claim Pending' ||
              item.status == 'Verification Pending')) {
        cards.add(
          _requesterWaitingCard(
            'Your claim request was sent. Please wait for the owner response.',
          ),
        );
      } else if (!isOwner && isRequester && item.status == 'Answer Submitted') {
        cards.add(_finderApprovalCard());
      }
    } else {
      if (!isOwner && item.status == 'Active') {
        cards.add(
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Report found ownership',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask a verification question before returning the item.',
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _primaryButton(
                  'ASK VERIFICATION QUESTION',
                  _showFoundQuestionDialog,
                ),
              ],
            ),
          ),
        );
      } else if (isOwner &&
          (item.status == 'Verification Pending' ||
              item.status == 'Claim Pending')) {
        cards.add(_ownerLostVerificationCard());
      } else if (!isOwner &&
          isRequester &&
          (item.status == 'Verification Pending' ||
              item.status == 'Claim Pending')) {
        cards.add(
          _requesterWaitingCard(
            'Your verification request was sent. Please wait for the owner response.',
          ),
        );
      } else if (!isOwner && isRequester && item.status == 'Answer Submitted') {
        cards.add(_finderApprovalCard());
      }
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final LostItem item = widget.item;
    final List<Widget> workflowCards = _buildWorkflowCards();

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Item Details',
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              child: Column(
                children: <Widget>[
                  _detailSection(
                    'Posted by',
                    _posterDisplayName(item),
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  _detailsTopCard(),
                  const SizedBox(height: 14),
                  _detailSection(
                    'Description',
                    item.description,
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: 14),
                  _ownerActionButtons(),
                  if (isOwner && isActiveStatus) const SizedBox(height: 14),
                  ...workflowCards.expand(
                    (Widget w) => <Widget>[w, const SizedBox(height: 14)],
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
